module Editable exposing (Editing(..), Model, Msg(..), init, isPressMsg, view)

import Effect.Browser.Dom as Dom exposing (HtmlId)
import Icons
import MyUi
import Ui exposing (Element)
import Ui.Font
import Ui.Input


type alias Model =
    { editing : Editing
    , pressedSubmit : Bool
    }


{-| OpaqueVariants
-}
type Editing
    = NotEditing
    | Editing String


type Msg value
    = Edit Model
    | PressedAcceptEdit value


init : Model
init =
    { editing = NotEditing
    , pressedSubmit = False
    }


isPressMsg : Msg a -> Bool
isPressMsg msg =
    case msg of
        Edit model ->
            False

        PressedAcceptEdit value ->
            True


view : HtmlId -> String -> (String -> Result String a) -> (Msg a -> msg) -> String -> Model -> Element msg
view htmlId label validation msg value model =
    let
        label2 =
            Ui.Input.label
                (Dom.idToString htmlId)
                [ Ui.Font.size 14, Ui.Font.bold ]
                (Ui.text label)

        result : Maybe (Result String a)
        result =
            case model.editing of
                NotEditing ->
                    Nothing

                Editing text ->
                    validation text |> Just
    in
    Ui.column
        [ Ui.widthMax 400 ]
        [ Ui.row
            []
            [ label2.element
            , case result of
                Just (Err error) ->
                    Ui.el
                        [ Ui.Font.color MyUi.errorColor
                        , Ui.Font.size 14
                        , Ui.paddingXY 8 0
                        , Ui.alignRight
                        , Ui.Font.bold
                        ]
                        (Ui.text error)

                _ ->
                    Ui.none
            ]
        , Ui.row
            [ Ui.height (Ui.px 40)
            ]
            (Ui.Input.text
                [ Ui.border 1
                , Ui.height Ui.fill
                , Ui.borderColor MyUi.inputBorder
                , Ui.background MyUi.inputBackground
                , case model.editing of
                    NotEditing ->
                        Ui.rounded 4

                    Editing _ ->
                        Ui.roundedWith { topLeft = 4, topRight = 0, bottomLeft = 4, bottomRight = 0 }
                , Ui.paddingXY 8 0
                ]
                { onChange = \text2 -> { model | editing = Editing text2 } |> Edit |> msg
                , text =
                    case model.editing of
                        NotEditing ->
                            value

                        Editing text ->
                            text
                , placeholder = Nothing
                , label = label2.id
                }
                :: (case result of
                        Just result2 ->
                            [ Ui.el
                                [ Ui.Input.button
                                    ((case result2 of
                                        Ok ok ->
                                            PressedAcceptEdit ok

                                        Err _ ->
                                            Edit { model | pressedSubmit = True }
                                     )
                                        |> msg
                                    )
                                , Ui.width (Ui.px 40)
                                , Ui.paddingXY 5 0
                                , Ui.height Ui.fill
                                , Ui.contentCenterX
                                , Ui.contentCenterY
                                , Ui.borderColor MyUi.inputBorder
                                , Ui.borderWith { left = 0, right = 0, top = 1, bottom = 1 }
                                , case result2 of
                                    Ok _ ->
                                        Ui.background MyUi.buttonBackground

                                    Err _ ->
                                        Ui.background MyUi.disabledButtonBackground
                                ]
                                (Ui.html Icons.checkmark)
                            , Ui.el
                                [ Ui.Input.button (Edit init |> msg)
                                , -- Is a little wider than the check button because it seems too skinny otherwise
                                  Ui.width (Ui.px 42)
                                , Ui.contentCenterX
                                , Ui.contentCenterY
                                , Ui.height Ui.fill
                                , Ui.borderColor MyUi.inputBorder
                                , Ui.border 1
                                , Ui.background MyUi.deleteButtonBackground
                                , Ui.Font.color MyUi.deleteButtonFont
                                , Ui.roundedWith { topLeft = 0, topRight = 4, bottomLeft = 0, bottomRight = 4 }
                                ]
                                (Ui.html (Icons.delete 24))
                            ]

                        Nothing ->
                            []
                   )
            )
        ]
