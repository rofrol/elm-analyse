module Analyser.Checks.ListOperatorsTests exposing (..)

import Analyser.Checks.ListOperators as ListOperators
import Analyser.Checks.CheckTestUtil as CTU
import Analyser.Messages.Types exposing (..)
import Test exposing (..)


couldUseCons : ( String, String, List MessageData )
couldUseCons =
    ( "couldUseCons"
    , """module Bar exposing (foo)

foo : Int
foo =
    [1] ++ [3, 4]
"""
    , [ DropConcatOfLists "./foo.elm" { start = { row = 4, column = 3 }, end = { row = 5, column = -2 } }
      ]
    )


noOptimisation : ( String, String, List MessageData )
noOptimisation =
    ( "noOptimisation"
    , """module Bar exposing (foo)

foo : Int
foo =
    [1, 2] ++ var
"""
    , []
    )


concatMultiElementList : ( String, String, List MessageData )
concatMultiElementList =
    ( "concatMultiElementList"
    , """module Bar exposing (foo)

foo : Int
foo =
    [1, 2] ++ [3, 4]
"""
    , [ DropConcatOfLists "./foo.elm" { start = { row = 4, column = 3 }, end = { row = 5, column = -2 } }
      ]
    )


concatSingleItemToVar : ( String, String, List MessageData )
concatSingleItemToVar =
    ( "concatSingleItemToVar"
    , """module Bar exposing (foo)

foo : Int
foo =
    [1] ++ bar
"""
    , [ UseConsOverConcat "./foo.elm" { start = { row = 4, column = 3 }, end = { row = 5, column = -2 } }
      ]
    )


consWithLiteralList : ( String, String, List MessageData )
consWithLiteralList =
    ( "consWithLiteralList"
    , """module Bar exposing (foo)

foo : Int
foo =
    1 :: [2 , 3]
"""
    , [ DropConsOfItemAndList "./foo.elm" { start = { row = 4, column = 3 }, end = { row = 5, column = -2 } }
      ]
    )


all : Test
all =
    CTU.build "Analyser.Checks.ListOperators"
        ListOperators.checker
        [ couldUseCons
        , noOptimisation
        , concatMultiElementList
        , concatSingleItemToVar
        , consWithLiteralList
        ]
