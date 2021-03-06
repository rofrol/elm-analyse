module Analyser.PostProcessing exposing (postProcess)

import Dict exposing (Dict)
import List exposing (maximum)
import AST.Ranges exposing (getRange)
import AST.Types
    exposing
        ( File
        , RecordUpdate
        , Expression
        , InnerExpression
            ( Application
            , Operator
            , OperatorApplication
            , RecordExpr
            , IfBlock
            , TupledExpression
            , ParenthesizedExpression
            , LetExpression
            , CaseExpression
            , LambdaExpression
            , ListExpr
            , RecordUpdateExpression
            )
        , Function
        , InfixDirection(Left)
        , Infix
        , Declaration(FuncDecl)
        , FunctionDeclaration
        )
import Analyser.Files.Types exposing (OperatorTable)
import Analyser.PostProcessing.Documentation as Documentation
import List.Extra as List
import Tuple2


postProcess : OperatorTable -> File -> File
postProcess table file =
    let
        operatorFixed =
            visit
                { onExpression =
                    Just
                        (\context inner expression ->
                            inner <|
                                case expression of
                                    ( r, Application args ) ->
                                        ( r, fixApplication context args )

                                    _ ->
                                        expression
                        )
                }
                table
                file
    in
        Documentation.postProcess operatorFixed


fixApplication : OperatorTable -> List Expression -> InnerExpression
fixApplication operators expressions =
    let
        ops : Dict String Infix
        ops =
            List.filterMap expressionOperators expressions
                |> List.map
                    (\x ->
                        ( x
                        , Dict.get x operators
                            |> Maybe.withDefault
                                { operator = x
                                , precedence = 5
                                , direction = Left
                                }
                        )
                    )
                |> highestPrecedence

        fixExprs : List Expression -> InnerExpression
        fixExprs exps =
            case exps of
                [ x ] ->
                    Tuple.second x

                _ ->
                    Application exps

        divideAndConquer : List Expression -> InnerExpression
        divideAndConquer exps =
            if Dict.isEmpty ops then
                fixExprs exps
            else
                findNextSplit ops exps
                    |> Maybe.map
                        (\( p, infix, s ) ->
                            OperatorApplication
                                infix.operator
                                infix.direction
                                ( getRange <| List.map Tuple.first p, divideAndConquer p )
                                ( getRange <| List.map Tuple.first s, divideAndConquer s )
                        )
                    |> Maybe.withDefault (fixExprs exps)
    in
        divideAndConquer expressions


findNextSplit : Dict String Infix -> List Expression -> Maybe ( List Expression, Infix, List Expression )
findNextSplit dict exps =
    let
        prefix =
            exps
                |> List.takeWhile
                    (\x ->
                        expressionOperators x
                            |> Maybe.andThen (flip Dict.get dict)
                            |> (==) Nothing
                    )

        suffix =
            List.drop (List.length prefix + 1) exps
    in
        exps
            |> List.drop (List.length prefix)
            |> List.head
            |> Maybe.andThen expressionOperators
            |> Maybe.andThen (\x -> Dict.get x dict)
            |> Maybe.map (\x -> ( prefix, x, suffix ))


highestPrecedence : List ( String, Infix ) -> Dict String Infix
highestPrecedence input =
    let
        maxi =
            input
                |> List.map (Tuple.second >> .precedence)
                |> maximum
    in
        maxi
            |> Maybe.map (\m -> List.filter (Tuple.second >> .precedence >> (==) m) input)
            |> Maybe.withDefault []
            |> Dict.fromList


expressionOperators : Expression -> Maybe String
expressionOperators ( _, expression ) =
    case expression of
        Operator s ->
            Just s

        _ ->
            Nothing


type alias Visitor a =
    { onExpression : Maybe (a -> (Expression -> Expression) -> Expression -> Expression) }


visit : Visitor context -> context -> File -> File
visit visitor context file =
    let
        newDeclarations =
            visitDeclarations visitor context file.declarations
    in
        { file | declarations = newDeclarations }


visitDeclarations : Visitor context -> context -> List Declaration -> List Declaration
visitDeclarations visitor context declarations =
    List.map (visitDeclaration visitor context) declarations


visitDeclaration : Visitor context -> context -> Declaration -> Declaration
visitDeclaration visitor context declaration =
    case declaration of
        FuncDecl function ->
            FuncDecl (visitFunctionDecl visitor context function)

        _ ->
            declaration


visitFunctionDecl : Visitor context -> context -> Function -> Function
visitFunctionDecl visitor context function =
    let
        newFunctionDeclaration =
            visitFunctionDeclaration visitor context function.declaration
    in
        { function | declaration = newFunctionDeclaration }


visitFunctionDeclaration : Visitor context -> context -> FunctionDeclaration -> FunctionDeclaration
visitFunctionDeclaration visitor context functionDeclaration =
    let
        newExpression =
            visitExpression visitor context functionDeclaration.expression
    in
        { functionDeclaration | expression = newExpression }


visitExpression : Visitor context -> context -> Expression -> Expression
visitExpression visitor context expression =
    let
        inner =
            visitExpressionInner visitor context
    in
        (visitor.onExpression |> Maybe.withDefault (\_ inner expr -> inner expr))
            context
            inner
            expression


visitExpressionInner : Visitor context -> context -> Expression -> Expression
visitExpressionInner visitor context ( r, expression ) =
    let
        subVisit =
            visitExpression visitor context
    in
        (,) r <|
            case expression of
                Application expressionList ->
                    expressionList
                        |> List.map subVisit
                        |> Application

                OperatorApplication op dir left right ->
                    OperatorApplication op
                        dir
                        (subVisit left)
                        (subVisit right)

                IfBlock e1 e2 e3 ->
                    IfBlock (subVisit e1) (subVisit e2) (subVisit e3)

                TupledExpression expressionList ->
                    expressionList
                        |> List.map subVisit
                        |> TupledExpression

                ParenthesizedExpression expr1 ->
                    ParenthesizedExpression (subVisit expr1)

                LetExpression letBlock ->
                    LetExpression
                        { declarations = visitDeclarations visitor context letBlock.declarations
                        , expression = subVisit letBlock.expression
                        }

                CaseExpression caseBlock ->
                    CaseExpression
                        { expression = subVisit caseBlock.expression
                        , cases = List.map (Tuple2.mapSecond subVisit) caseBlock.cases
                        }

                LambdaExpression lambda ->
                    LambdaExpression <| { lambda | expression = subVisit lambda.expression }

                RecordExpr expressionStringList ->
                    expressionStringList
                        |> List.map (Tuple2.mapSecond subVisit)
                        |> RecordExpr

                ListExpr expressionList ->
                    ListExpr (List.map subVisit expressionList)

                RecordUpdateExpression recordUpdate ->
                    recordUpdate.updates
                        |> List.map (Tuple.mapSecond subVisit)
                        |> (RecordUpdate recordUpdate.name >> RecordUpdateExpression)

                _ ->
                    expression
