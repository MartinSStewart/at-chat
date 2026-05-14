module NoRedundantUiAttributesTest exposing (all)

import NoRedundantUiAttributes
import Review.Test
import Test exposing (Test)


all : Test
all =
    Test.describe "NoRedundantUiAttributes"
        [ Test.test "reports Ui.width Ui.fill as the default and removes it" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.spacing 4, Ui.width Ui.fill, Ui.alignTop ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.width Ui.fill is the default and can be removed"
                            , details =
                                [ "Elements in elm-ui already have `Ui.width Ui.fill` applied by default, so adding this attribute explicitly has no effect."
                                , "Remove this attribute to reduce noise in the attribute list."
                                ]
                            , under = "Ui.width Ui.fill"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.spacing 4, Ui.alignTop ] (Ui.text "hi")
"""
                        ]
        , Test.test "does not report Ui.width with a non-fill argument" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.width (Ui.px 100) ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectNoErrors
        , Test.test "removes the earlier of two conflicting alignments at the START of a list" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.alignTop, Ui.alignBottom, Ui.spacing 5 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.alignTop is overridden by a later Ui.alignBottom"
                            , details =
                                [ "Both Ui.alignTop and Ui.alignBottom appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.alignTop"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.alignBottom, Ui.spacing 5 ] (Ui.text "hi")
"""
                        ]
        , Test.test "removes the earlier of two conflicting alignments in the MIDDLE of a list" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.spacing 5, Ui.alignTop, Ui.alignBottom, Ui.padding 8 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.alignTop is overridden by a later Ui.alignBottom"
                            , details =
                                [ "Both Ui.alignTop and Ui.alignBottom appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.alignTop"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.spacing 5, Ui.alignBottom, Ui.padding 8 ] (Ui.text "hi")
"""
                        ]
        , Test.test "removes the earlier of two Ui.Font.color at the START of a list" <|
            \() ->
                """module A exposing (..)

import Ui
import Ui.Font

red = Ui.rgb 255 0 0
blue = Ui.rgb 0 0 255

view =
    Ui.el [ Ui.Font.color red, Ui.Font.color blue, Ui.padding 8 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.Font.color is overridden by a later Ui.Font.color"
                            , details =
                                [ "Both Ui.Font.color and Ui.Font.color appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.Font.color red"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui
import Ui.Font

red = Ui.rgb 255 0 0
blue = Ui.rgb 0 0 255

view =
    Ui.el [ Ui.Font.color blue, Ui.padding 8 ] (Ui.text "hi")
"""
                        ]
        , Test.test "removes the earlier of two Ui.Font.color in the MIDDLE of a list" <|
            \() ->
                """module A exposing (..)

import Ui
import Ui.Font

red = Ui.rgb 255 0 0
blue = Ui.rgb 0 0 255

view =
    Ui.el [ Ui.padding 8, Ui.Font.color red, Ui.Font.color blue, Ui.spacing 4 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.Font.color is overridden by a later Ui.Font.color"
                            , details =
                                [ "Both Ui.Font.color and Ui.Font.color appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.Font.color red"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui
import Ui.Font

red = Ui.rgb 255 0 0
blue = Ui.rgb 0 0 255

view =
    Ui.el [ Ui.padding 8, Ui.Font.color blue, Ui.spacing 4 ] (Ui.text "hi")
"""
                        ]
        , Test.test "removes paddingLeft when followed by paddingWith" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.paddingLeft 5, Ui.paddingWith { top = 1, right = 2, bottom = 3, left = 4 } ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.paddingLeft is overridden by a later Ui.paddingWith"
                            , details =
                                [ "Both Ui.paddingLeft and Ui.paddingWith appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.paddingLeft 5"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.paddingWith { top = 1, right = 2, bottom = 3, left = 4 } ] (Ui.text "hi")
"""
                        ]
        , Test.test "removes the first of two padding shorthands" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.padding 5, Ui.paddingXY 1 2 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.padding is overridden by a later Ui.paddingXY"
                            , details =
                                [ "Both Ui.padding and Ui.paddingXY appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.padding 5"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.paddingXY 1 2 ] (Ui.text "hi")
"""
                        ]
        , Test.test "allows paddingLeft and paddingRight together (different sides)" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.paddingLeft 5, Ui.paddingRight 10 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectNoErrors
        , Test.test "removes the earlier of two paddingLeft on the same side" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.paddingLeft 5, Ui.paddingLeft 10 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.paddingLeft is overridden by a later Ui.paddingLeft"
                            , details =
                                [ "Both Ui.paddingLeft and Ui.paddingLeft appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.paddingLeft 5"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.paddingLeft 10 ] (Ui.text "hi")
"""
                        ]

        --        , Test.test "resolves module names through exposing imports" <|
        --            \() ->
        --                """module A exposing (..)
        --
        --import Ui exposing (alignTop, alignBottom, el, text)
        --
        --view =
        --    el [ alignTop, alignBottom ] (text "hi")
        --"""
        --                    |> String.replace "\u{000D}" ""
        --                    |> Review.Test.run NoRedundantUiAttributes.rule
        --                    |> Review.Test.expectErrors
        --                        [ Review.Test.error
        --                            { message = "Ui.alignTop is overridden by a later Ui.alignBottom"
        --                            , details =
        --                                [ "Both Ui.alignTop and Ui.alignBottom appear in the same attribute list and either set the same property or conflict with each other."
        --                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
        --                                ]
        --                            , under = "alignTop"
        --                            }
        --                            |> Review.Test.whenFixed
        --                                """module A exposing (..)
        --
        --import Ui exposing (alignTop, alignBottom, el, text)
        --
        --view =
        --    el [ alignBottom ] (text "hi")
        --"""
        --                        ]
        , Test.test "does not report unrelated lists" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.alignTop ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectNoErrors
        , Test.test "removes background when followed by backgroundGradient" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.background (Ui.rgb 1 2 3), Ui.backgroundGradient [] ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.background is overridden by a later Ui.backgroundGradient"
                            , details =
                                [ "Both Ui.background and Ui.backgroundGradient appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.background (Ui.rgb 1 2 3)"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.backgroundGradient [] ] (Ui.text "hi")
"""
                        ]
        , Test.test "removes Ui.Font.bold when followed by Ui.Font.weight" <|
            \() ->
                """module A exposing (..)

import Ui
import Ui.Font

view =
    Ui.el [ Ui.Font.bold, Ui.Font.weight 400 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.Font.bold is overridden by a later Ui.Font.weight"
                            , details =
                                [ "Both Ui.Font.bold and Ui.Font.weight appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.Font.bold"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui
import Ui.Font

view =
    Ui.el [ Ui.Font.weight 400 ] (Ui.text "hi")
"""
                        ]
        , Test.test "does not flag a non-attribute list of values" <|
            \() ->
                """module A exposing (..)

xs = [ 1, 2, 3 ]
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectNoErrors
        , Test.test "keeps only the last when three Ui.Font.color attributes appear in a row" <|
            \() ->
                """module A exposing (..)

import Ui
import Ui.Font

a = Ui.rgb 1 0 0
b = Ui.rgb 0 1 0
c = Ui.rgb 0 0 1

view =
    Ui.el [ Ui.spacing 4, Ui.Font.color a, Ui.Font.color b, Ui.Font.color c, Ui.padding 8 ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.Font.color is overridden by a later Ui.Font.color"
                            , details =
                                [ "Both Ui.Font.color and Ui.Font.color appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.Font.color a"
                            }
                        , Review.Test.error
                            { message = "Ui.Font.color is overridden by a later Ui.Font.color"
                            , details =
                                [ "Both Ui.Font.color and Ui.Font.color appear in the same attribute list and either set the same property or conflict with each other."
                                , "Only the last one will take effect, so this earlier attribute is redundant and can be removed."
                                ]
                            , under = "Ui.Font.color b"
                            }
                            |> Review.Test.whenFixed
                                """module A exposing (..)

import Ui
import Ui.Font

a = Ui.rgb 1 0 0
b = Ui.rgb 0 1 0
c = Ui.rgb 0 0 1

view =
    Ui.el [ Ui.spacing 4, Ui.Font.color c, Ui.padding 8 ] (Ui.text "hi")
"""
                        ]
        ]
