module Analyser.Fixes.UnusedPatternVariable exposing (fixer)

import Analyser.Fixes.FileContent as FileContent
import AST.Ranges exposing (Range)
import AST.Types exposing (File, Pattern, Function, Case)
import Analyser.Messages.Types exposing (MessageData(UnusedPatternVariable))
import ASTUtil.PatternOptimizer as PatternOptimizer
import ASTUtil.Patterns as Patterns
import ASTUtil.ASTWriter as ASTWriter
import Analyser.Fixes.Base exposing (Fixer)


fixer : Fixer
fixer =
    Fixer canFix fix


canFix : MessageData -> Bool
canFix message =
    case message of
        UnusedPatternVariable _ _ _ ->
            True

        _ ->
            False


fix : List ( String, String, File ) -> MessageData -> Result String (List ( String, String ))
fix input messageData =
    case messageData of
        UnusedPatternVariable _ _ range ->
            case List.head input of
                Nothing ->
                    Err "No input for fixer UnusedPatternVariable"

                Just triple ->
                    fixPattern triple range

        _ ->
            Err "Invalid message data for fixer UnusedPatternVariable"


fixPattern : ( String, String, File ) -> Range -> Result String (List ( String, String ))
fixPattern ( fileName, content, ast ) range =
    case Patterns.findParentPattern ast range of
        Just parentPattern ->
            Ok
                [ ( fileName
                  , FileContent.replaceRangeWith
                        (PatternOptimizer.patternRange parentPattern)
                        (ASTWriter.writePattern (PatternOptimizer.optimize range parentPattern)
                            |> ASTWriter.write
                        )
                        content
                  )
                ]

        Nothing ->
            Err "Could not find location to replace unused variable in pattern"
