module NoRedundantUiAttributesTest exposing (all)

import NoRedundantUiAttributes
import Review.Test
import Test exposing (Test)


all : Test
all =
    Test.describe "NoRedundantUiAttributes"
        [ Test.test "reports Ui.width Ui.fill as the default" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.width Ui.fill ] (Ui.text "hi")
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
        , Test.test "reports conflicting vertical alignments" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.alignTop, Ui.alignBottom ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.alignBottom is redundant with Ui.alignTop"
                            , details =
                                [ "Both Ui.alignTop and Ui.alignBottom appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.alignBottom"
                            }
                        ]
        , Test.test "reports conflicting horizontal alignments" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.alignLeft, Ui.centerX ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.centerX is redundant with Ui.alignLeft"
                            , details =
                                [ "Both Ui.alignLeft and Ui.centerX appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.centerX"
                            }
                        ]
        , Test.test "allows alignTop combined with alignLeft (different axes)" <|
            \() ->
                """module A exposing (..)

import Ui

view =
    Ui.el [ Ui.alignTop, Ui.alignLeft ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectNoErrors
        , Test.test "reports paddingLeft combined with paddingWith" <|
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
                            { message = "Ui.paddingWith is redundant with Ui.paddingLeft"
                            , details =
                                [ "Both Ui.paddingLeft and Ui.paddingWith appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.paddingWith { top = 1, right = 2, bottom = 3, left = 4 }"
                            }
                        ]
        , Test.test "reports two padding shorthands together" <|
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
                            { message = "Ui.paddingXY is redundant with Ui.padding"
                            , details =
                                [ "Both Ui.padding and Ui.paddingXY appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.paddingXY 1 2"
                            }
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
        , Test.test "reports two paddingLeft on the same side" <|
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
                            { message = "Ui.paddingLeft is redundant with Ui.paddingLeft"
                            , details =
                                [ "Both Ui.paddingLeft and Ui.paddingLeft appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.paddingLeft 10"
                            }
                        ]
        , Test.test "reports two Ui.Font.color attributes" <|
            \() ->
                """module A exposing (..)

import Ui
import Ui.Font

red = Ui.rgb 255 0 0
blue = Ui.rgb 0 0 255

view =
    Ui.el [ Ui.Font.color red, Ui.Font.color blue ] (Ui.text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.Font.color is redundant with Ui.Font.color"
                            , details =
                                [ "Both Ui.Font.color and Ui.Font.color appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.Font.color blue"
                            }
                        ]
        , Test.test "resolves module names through exposing imports" <|
            \() ->
                """module A exposing (..)

import Ui exposing (alignTop, alignBottom, el, text)

view =
    el [ alignTop, alignBottom ] (text "hi")
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "Ui.alignBottom is redundant with Ui.alignTop"
                            , details =
                                [ "Both Ui.alignTop and Ui.alignBottom appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "alignBottom"
                            }
                        ]
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
        , Test.test "reports background and backgroundGradient together" <|
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
                            { message = "Ui.backgroundGradient is redundant with Ui.background"
                            , details =
                                [ "Both Ui.background and Ui.backgroundGradient appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.backgroundGradient []"
                            }
                        ]
        , Test.test "reports Ui.Font.bold and Ui.Font.weight together" <|
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
                            { message = "Ui.Font.weight is redundant with Ui.Font.bold"
                            , details =
                                [ "Both Ui.Font.bold and Ui.Font.weight appear in the same attribute list and either set the same property or conflict with each other."
                                , "An element can only have one value for this property, so only the last one will take effect. Remove one of these attributes to make the intent clear."
                                ]
                            , under = "Ui.Font.weight 400"
                            }
                        ]
        , Test.test "does not flag a non-attribute list of values" <|
            \() ->
                """module A exposing (..)

xs = [ 1, 2, 3 ]
"""
                    |> String.replace "\u{000D}" ""
                    |> Review.Test.run NoRedundantUiAttributes.rule
                    |> Review.Test.expectNoErrors
        ]
