module AST.Types exposing (..)

import AST.Ranges exposing (Range)


type alias VariablePointer =
    { value : String
    , range : Range
    }


type alias File =
    { moduleDefinition : Module
    , imports : List Import
    , declarations : List Declaration
    , comments : List ( String, Range )
    }


type Module
    = NormalModule DefaultModuleData
    | PortModule DefaultModuleData
    | EffectModule EffectModuleData
    | NoModule


type alias DefaultModuleData =
    { moduleName : ModuleName
    , exposingList : Exposure Expose
    }


type alias EffectModuleData =
    { moduleName : ModuleName
    , exposingList : Exposure Expose
    , command : Maybe String
    , subscription : Maybe String
    }


type alias ModuleName =
    List String


type Declaration
    = FuncDecl Function
    | AliasDecl TypeAlias
    | TypeDecl Type
    | PortDeclaration FunctionSignature
    | InfixDeclaration Infix
    | DestructuringDeclaration Destructuring


type alias Destructuring =
    { pattern : Pattern
    , expression : Expression
    }


type InfixDirection
    = Left
    | Right


type alias Infix =
    { direction : InfixDirection
    , precedence : Int
    , operator : String
    }


type alias DocumentationComment =
    ( String, Range )


type Pattern
    = AllPattern Range
    | UnitPattern Range
    | CharPattern Char Range
    | StringPattern String Range
    | IntPattern Int Range
    | FloatPattern Float Range
    | TuplePattern (List Pattern) Range
    | RecordPattern (List VariablePointer) Range
    | UnConsPattern Pattern Pattern Range
    | ListPattern (List Pattern) Range
    | VarPattern String Range
    | NamedPattern QualifiedNameRef (List Pattern) Range
    | QualifiedNamePattern QualifiedNameRef Range
    | AsPattern Pattern VariablePointer Range
    | ParenthesizedPattern Pattern Range


type alias QualifiedNameRef =
    { moduleName : List String
    , name : String
    }



-- Functions


type alias FunctionSignature =
    { operatorDefinition : Bool
    , name : String
    , typeReference : TypeReference
    , range : Range
    }


type alias FunctionDeclaration =
    { operatorDefinition : Bool
    , name : VariablePointer
    , arguments : List Pattern
    , expression : Expression
    }


type alias Function =
    { documentation : Maybe DocumentationComment
    , signature : Maybe FunctionSignature
    , declaration : FunctionDeclaration
    }



-- Expressions


type alias Expression =
    ( Range, InnerExpression )


type InnerExpression
    = UnitExpr
    | Application (List Expression)
    | OperatorApplication String InfixDirection Expression Expression
    | FunctionOrValue String
    | IfBlock Expression Expression Expression
    | PrefixOperator String
    | Operator String
    | Integer Int
    | Floatable Float
    | Negation Expression
    | Literal String
    | CharLiteral Char
    | TupledExpression (List Expression)
    | ParenthesizedExpression Expression
    | LetExpression LetBlock
    | CaseExpression CaseBlock
    | LambdaExpression Lambda
    | RecordExpr (List RecordSetter)
    | ListExpr (List Expression)
    | QualifiedExpr ModuleName String
    | RecordAccess Expression String
    | RecordAccessFunction String
    | RecordUpdateExpression RecordUpdate
    | GLSLExpression String


type alias RecordUpdate =
    { name : String
    , updates : List RecordSetter
    }


type alias RecordSetter =
    ( String, Expression )


type alias CaseBlock =
    { expression : Expression
    , cases : Cases
    }


type alias LetBlock =
    { declarations : List Declaration
    , expression : Expression
    }


type alias Lambda =
    { args : List Pattern
    , expression : Expression
    }


type alias Case =
    ( Pattern, Expression )


type alias Cases =
    List Case



-- Type Referencing


type alias TypeAlias =
    { documentation : Maybe DocumentationComment
    , name : String
    , generics : List String
    , typeReference : TypeReference
    , range : Range
    }


type alias Type =
    { name : String
    , generics : List String
    , constructors : List ValueConstructor
    }


type alias ValueConstructor =
    { name : String
    , arguments : List TypeReference
    , range : Range
    }


type TypeReference
    = GenericType String Range
    | Typed ModuleName String (List TypeReference) Range
    | Unit Range
    | Tupled (List TypeReference) Range
    | Record RecordDefinition Range
    | GenericRecord String RecordDefinition Range
    | FunctionTypeReference TypeReference TypeReference Range


type alias RecordDefinition =
    List RecordField


type alias RecordField =
    ( String, TypeReference )



-- Import


type alias Import =
    { moduleName : ModuleName
    , moduleAlias : Maybe ModuleName
    , exposingList : Exposure Expose
    , range : Range
    }



-- Exposing


type Exposure a
    = None
    | All Range
    | Explicit (List a)


type Expose
    = InfixExpose String Range
    | FunctionExpose String Range
    | TypeOrAliasExpose String Range
    | TypeExpose ExposedType


type alias ExposedType =
    { name : String
    , constructors : Exposure ValueConstructorExpose
    , range : Range
    }


type alias ValueConstructorExpose =
    ( String, Range )
