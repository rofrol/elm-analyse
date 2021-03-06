module Analyser.Checks.UnusedTypeAliasTests exposing (..)

import Analyser.Checks.CheckTestUtil as CTU
import Analyser.Checks.UnusedTypeAlias as UnusedTypeAlias
import Analyser.Messages.Types exposing (..)
import Test exposing (Test)


unusedButExposed : ( String, String, List MessageData )
unusedButExposed =
    ( "unusedButExposed"
    , """module Foo exposing (Bar)

type alias Bar = Int
"""
    , []
    )


usedInSignature : ( String, String, List MessageData )
usedInSignature =
    ( "usedInSignature"
    , """module Foo exposing (foo)

type alias Bar = Int
foo : Bar
foo = 1

"""
    , []
    )


usedAsFunction : ( String, String, List MessageData )
usedAsFunction =
    ( "usedAsFunction"
    , """module Foo exposing (foo)

type alias Person = { name : String, age : Int}

foo =
    Person "John" 12

"""
    , []
    )


usedInPort : ( String, String, List MessageData )
usedInPort =
    ( "usedInPort"
    , """module Foo exposing (foo)

type alias Person = { name : String, age : Int}

port foo : Person -> Cmd msg


"""
    , []
    )


usedAliasInRecord : ( String, String, List MessageData )
usedAliasInRecord =
    ( "usedAliasInRecord"
    , """module Foo exposing (InputInterfaces)

type alias InputFiles =
    List String


type alias InputInterfaces =
    List ( String, InputFiles )
"""
    , []
    )


usedAliasInType : ( String, String, List MessageData )
usedAliasInType =
    ( "usedAliasInType"
    , """module Foo exposing (Patch(..))

type alias InputFiles =
    List String


type Patch
    = OnFiles InputFiles
"""
    , []
    )


unusedTypeAlias : ( String, String, List MessageData )
unusedTypeAlias =
    ( "unusedTypeAlias"
    , """module Foo exposing (foo)

type alias Person = { name : String, age : Int}

foo = 1
"""
    , [ UnusedTypeAlias "./foo.elm" "Person" { start = { row = 2, column = -1 }, end = { row = 3, column = -2 } }
      ]
    )


all : Test
all =
    CTU.build "Analyser.Checks.UnusedTypeAliasTests"
        UnusedTypeAlias.checker
        [ unusedButExposed
        , usedInSignature
        , usedAsFunction
        , usedInPort
        , usedAliasInRecord
        , usedAliasInType
        , unusedTypeAlias
        ]
