module TextEditor exposing
    ( LocalChange
    , LocalState
    , Model
    , Msg
    , ServerChange
    , backendChangeUpdate
    , changeUpdate
    , init
    , initLocalState
    , isPress
    , localChangeUpdate
    , update
    , view
    )

import Effect.Browser.Dom as Dom
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (Id, UserId)
import Json.Decode
import MyUi
import RichText exposing (Range)
import SeqDict exposing (SeqDict)
import String.Extra
import String.Nonempty
import Ui exposing (Element)


type Msg
    = TypedText String
    | MovedCursor Range
    | PressedReset


type LocalChange
    = Local_TypedText String
    | Local_MovedCursor Range
    | Local_Reset
    | Local_Backspace Int


type ServerChange
    = Server_TypedText (Id UserId) String
    | Server_MovedCursor (Id UserId) Range
    | Server_Reset
    | Server_Backspace (Id UserId) Int


type alias Model =
    {}


type alias LocalState =
    { text : String
    , cursorPosition : SeqDict (Id UserId) Range
    }


init : Model
init =
    {}


initLocalState : LocalState
initLocalState =
    { text = "", cursorPosition = SeqDict.empty }


update : Id UserId -> Msg -> Model -> LocalState -> ( Model, Maybe LocalChange )
update currentUserId msg model local =
    case msg of
        TypedText text ->
            case SeqDict.get currentUserId local.cursorPosition of
                Just range ->
                    let
                        _ =
                            Debug.log "range" range

                        _ =
                            Debug.log "input text" text

                        lengthDiff : Int
                        lengthDiff =
                            String.length text - String.length (Debug.log "old" local.text) |> Debug.log "lengthDiff"
                    in
                    ( model
                    , if RichText.rangeSize range == 0 && lengthDiff < 0 then
                        Local_Backspace -lengthDiff |> Just

                      else
                        String.slice range.start (range.start + lengthDiff + RichText.rangeSize range) text
                            |> Debug.log "new text"
                            |> Local_TypedText
                            |> Just
                    )

                Nothing ->
                    ( model, Nothing )

        MovedCursor range ->
            ( model, Local_MovedCursor range |> Just )

        PressedReset ->
            ( model, Local_Reset |> Just )


localChangeUpdate : Id UserId -> LocalChange -> LocalState -> LocalState
localChangeUpdate currentUserId change local =
    case change of
        Local_TypedText text ->
            insertText currentUserId text local

        Local_MovedCursor range ->
            { local | cursorPosition = SeqDict.insert currentUserId range local.cursorPosition }

        Local_Reset ->
            initLocalState

        Local_Backspace backspaceCount ->
            backspaceText currentUserId backspaceCount local


changeUpdate : ServerChange -> LocalState -> LocalState
changeUpdate change local =
    case change of
        Server_TypedText userId text ->
            insertText userId text local

        Server_MovedCursor userId range ->
            { local | cursorPosition = SeqDict.insert userId range local.cursorPosition }

        Server_Reset ->
            initLocalState

        Server_Backspace userId backspaceCount ->
            backspaceText userId backspaceCount local


backspaceText : Id UserId -> Int -> LocalState -> LocalState
backspaceText userId backspaceCount local =
    case SeqDict.get userId local.cursorPosition of
        Just range ->
            { local
                | text = String.Extra.replaceSlice "" (range.start - backspaceCount) range.end local.text
                , cursorPosition =
                    SeqDict.map
                        (\_ range2 ->
                            { start =
                                if range.start <= range2.start then
                                    range2.start - backspaceCount

                                else
                                    range2.start
                            , end =
                                if range.start <= range2.end then
                                    range2.end - backspaceCount

                                else
                                    range2.end
                            }
                        )
                        local.cursorPosition
            }

        Nothing ->
            local


insertText : Id UserId -> String -> LocalState -> LocalState
insertText userId text local =
    case SeqDict.get userId local.cursorPosition of
        Just range ->
            let
                rangeSize2 =
                    RichText.rangeSize range

                moveBy : Int
                moveBy =
                    String.length text - rangeSize2
            in
            { local
                | text = String.Extra.replaceSlice text range.start range.end local.text
                , cursorPosition =
                    SeqDict.map
                        (\_ range2 ->
                            { start =
                                if range.start <= range2.start then
                                    range2.start + moveBy

                                else
                                    range2.start
                            , end =
                                if range.start <= range2.end then
                                    range2.end + moveBy

                                else
                                    range2.end
                            }
                        )
                        local.cursorPosition
            }

        Nothing ->
            local


backendChangeUpdate :
    Id UserId
    -> LocalChange
    -> LocalState
    -> ( LocalState, ServerChange )
backendChangeUpdate currentUserId change local =
    case change of
        Local_TypedText text ->
            ( insertText currentUserId text local
            , Server_TypedText currentUserId text
            )

        Local_MovedCursor range ->
            ( { local | cursorPosition = SeqDict.insert currentUserId range local.cursorPosition }
            , Server_MovedCursor currentUserId range
            )

        Local_Reset ->
            ( initLocalState, Server_Reset )

        Local_Backspace backspaceCount ->
            ( backspaceText currentUserId backspaceCount local
            , Server_Backspace currentUserId backspaceCount
            )


view : Bool -> LocalState -> Element Msg
view isMobile local =
    Ui.el
        [ Ui.height Ui.fill
        , Ui.inFront
            (MyUi.elButton
                (Dom.id "textEditor_reset")
                PressedReset
                [ Ui.width Ui.shrink
                , Ui.alignRight
                , Ui.paddingXY 16 8
                , Ui.background MyUi.buttonBackground
                , Ui.border 1
                , Ui.borderColor MyUi.buttonBorder
                ]
                (Ui.text "Reset")
            )
        ]
        (textarea local isMobile "Nothing written yet..." local.text |> Ui.html)


isPress : Msg -> Bool
isPress msg =
    case msg of
        TypedText string ->
            False

        MovedCursor range ->
            False

        PressedReset ->
            True


selectionDecoder : Json.Decode.Decoder Range
selectionDecoder =
    Json.Decode.map2 (\start end -> Range (min start end) (max start end))
        (Json.Decode.at [ "target", "selectionStart" ] Json.Decode.int)
        (Json.Decode.at [ "target", "selectionEnd" ] Json.Decode.int)


textarea : LocalState -> Bool -> String -> String -> Html Msg
textarea local isMobileKeyboard placeholderText text =
    Html.div
        ([ Html.Attributes.style "display" "flex"
         , Html.Attributes.style "position" "relative"
         , Html.Attributes.style "min-height" "min-content"
         , Html.Attributes.style "width" "100%"
         , Html.Attributes.style "height" "fit-content"
         ]
            ++ (if isMobileKeyboard then
                    [ Html.Attributes.style "min-height" "100%" ]

                else
                    []
               )
        )
        [ Html.textarea
            [ Html.Attributes.style "color" "rgba(255,0,0,1)"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "line-height" "inherit"
            , Html.Attributes.style "width" "calc(100% - 18px)"
            , Html.Attributes.style "height" "calc(100% - 2px)"
            , Html.Attributes.style "background-color" "transparent"
            , Html.Attributes.style "border" "0"
            , Html.Attributes.style "resize" "none"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "caret-color" "white"
            , Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "outline" "none"
            , Html.Events.onInput TypedText
            , Html.Attributes.value text
            , Html.Events.on "selectionchange" (Json.Decode.map MovedCursor selectionDecoder)
            ]
            []
        , Html.div
            [ Html.Attributes.style "pointer-events" "none"
            , Html.Attributes.style "padding" "0 9px 0 9px"
            , Html.Attributes.style "transform" "translateX(-1px) translateY(8px)"
            , Html.Attributes.style "white-space" "pre-wrap"
            , Html.Attributes.style "overflow-wrap" "anywhere"
            , Html.Attributes.style "height" "fit-content"
            , Html.Attributes.style "min-height" "100%"
            , Html.Attributes.style "color"
                (if text == "" then
                    "rgb(180,180,180)"

                 else
                    "rgb(255,255,255)"
                )
            ]
            (case String.Nonempty.fromString text of
                Just nonempty ->
                    let
                        users =
                            SeqDict.empty
                    in
                    RichText.textInputView
                        local.cursorPosition
                        users
                        SeqDict.empty
                        (RichText.fromNonemptyString users nonempty)
                        ++ [ Html.text "\n" ]

                Nothing ->
                    [ if placeholderText == "" then
                        Html.text " "

                      else
                        Html.text placeholderText
                    ]
            )
        ]
