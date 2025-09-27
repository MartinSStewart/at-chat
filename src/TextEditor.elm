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
    , inputId
    , isPress
    , localChangeUpdate
    , update
    , view
    )

import Color exposing (Color)
import Color.Interpolate exposing (Space(..))
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (Id, UserId)
import Json.Decode
import List.Extra
import MyUi
import RichText exposing (Range)
import SeqDict exposing (SeqDict)
import SeqSet
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
    { text = "0123456789", cursorPosition = SeqDict.empty }


update : Id UserId -> Msg -> Model -> LocalState -> ( Model, Maybe LocalChange )
update currentUserId msg model local =
    case msg of
        TypedText text ->
            case SeqDict.get currentUserId local.cursorPosition of
                Just range ->
                    let
                        lengthDiff : Int
                        lengthDiff =
                            String.length text - String.length local.text
                    in
                    ( model
                    , if RichText.rangeSize range == 0 && lengthDiff < 0 then
                        Local_Backspace -lengthDiff |> Just

                      else
                        String.slice range.start (range.start + lengthDiff + RichText.rangeSize range) text
                            |> Local_TypedText
                            |> Just
                    )

                Nothing ->
                    ( model, Nothing )

        MovedCursor range ->
            if range.start == range.end && range.start == String.length local.text then
                ( model, Nothing )

            else
                case SeqDict.get currentUserId local.cursorPosition of
                    Just previousRange ->
                        ( model
                        , if range == previousRange then
                            Nothing

                          else
                            Local_MovedCursor range |> Just
                        )

                    Nothing ->
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
        Just removalRange ->
            { local
                | text = String.Extra.replaceSlice "" (removalRange.start - backspaceCount) removalRange.end local.text
                , cursorPosition =
                    SeqDict.map
                        (\_ range2 ->
                            insertTextHelper
                                0
                                { start = removalRange.start - backspaceCount, end = removalRange.end }
                                range2
                        )
                        local.cursorPosition
            }

        Nothing ->
            local


insertTextHelper : Int -> Range -> Range -> Range
insertTextHelper insertCount removeRange range =
    let
        size : Int
        size =
            RichText.rangeSize removeRange

        moveStartBy : Int
        moveStartBy =
            if removeRange.start < range.start then
                insertCount

            else
                0

        moveEndBy : Int
        moveEndBy =
            if removeRange.start < range.end then
                insertCount

            else
                0
    in
    if removeRange.end <= range.start then
        { start = range.start - size + insertCount
        , end = range.end - size + insertCount
        }

    else if removeRange.end <= range.end then
        { start = range.start - max 0 (range.start - removeRange.start) + moveStartBy
        , end = range.end - size + moveEndBy
        }

    else
        { start = range.start - max 0 (range.start - removeRange.start) + moveStartBy
        , end = range.end - max 0 (range.end - removeRange.start) + moveEndBy
        }


insertText : Id UserId -> String -> LocalState -> LocalState
insertText userId text local =
    case SeqDict.get userId local.cursorPosition of
        Just insertionRange ->
            let
                insertCount : Int
                insertCount =
                    String.length text
            in
            { local
                | text = String.Extra.replaceSlice text insertionRange.start insertionRange.end local.text
                , cursorPosition =
                    SeqDict.map
                        (\_ range -> insertTextHelper insertCount insertionRange range)
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


inputId : HtmlId
inputId =
    Dom.id "textEditor_input"


view : Bool -> Id UserId -> LocalState -> Element Msg
view isMobile currentUserId local =
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
        (textarea local isMobile currentUserId "Nothing written yet..." local.text |> Ui.html)


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


textarea : LocalState -> Bool -> Id UserId -> String -> String -> Html Msg
textarea local isMobileKeyboard currentUserId placeholderText text =
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
            , Dom.idToAttribute inputId
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
                    highlightText text currentUserId local ++ [ Html.text "\n" ]

                Nothing ->
                    [ if placeholderText == "" then
                        Html.text " "

                      else
                        Html.text placeholderText
                    ]
            )
        ]


type RangeType
    = PointRange
    | StartRange
    | EndRange


userIdColor : Id UserId -> Color.Color
userIdColor userId =
    case modBy 6 (Id.toInt userId) of
        0 ->
            Color.rgb255 230 0 0

        1 ->
            Color.rgb255 0 200 0

        2 ->
            Color.rgb255 200 200 0

        3 ->
            Color.rgb255 0 210 210

        4 ->
            Color.rgb255 210 0 210

        _ ->
            Color.rgb255 210 150 150


mixColors : Color -> List Color -> Color
mixColors first rest =
    let
        count =
            1 + List.length rest |> toFloat
    in
    List.map Color.toRgba (first :: rest)
        |> List.foldl
            (\a b ->
                { r = a.red / count + b.r
                , g = a.green / count + b.g
                , b = a.blue / count + b.b
                }
            )
            { r = 0, g = 0, b = 0 }
        |> (\a -> Color.rgb a.r a.g a.b)


highlightText : String -> Id UserId -> LocalState -> List (Html msg)
highlightText text currentUserId local =
    let
        list =
            SeqDict.toList (SeqDict.remove currentUserId local.cursorPosition)
    in
    case List.sortBy (\( _, range ) -> range.start) list of
        ( _, first ) :: _ ->
            list
                |> List.concatMap
                    (\( userId, range ) ->
                        if range.start == range.end then
                            [ ( userId, range.start, PointRange ) ]

                        else
                            [ ( userId, range.start, StartRange ), ( userId, range.end, EndRange ) ]
                    )
                |> List.sortBy (\( _, pos, _ ) -> pos)
                |> List.foldl
                    (\( userId, pos, isStart ) state ->
                        case isStart of
                            PointRange ->
                                { activeSelections = state.activeSelections
                                , html =
                                    state.html
                                        ++ [ case state.activeSelections of
                                                head :: rest ->
                                                    Html.span
                                                        [ mixColors (userIdColor head) (List.map userIdColor rest)
                                                            |> MyUi.colorToStyle
                                                            |> Html.Attributes.style "background-color"
                                                        ]
                                                        [ Html.text (String.slice state.lastPos pos text) ]

                                                [] ->
                                                    Html.text (String.slice state.lastPos pos text)
                                           , Html.span
                                                [ Html.Attributes.style "position" "relative" ]
                                                [ Html.div
                                                    [ Html.Attributes.style "position" "absolute"
                                                    , Html.Attributes.style "width" "4px"
                                                    , Html.Attributes.style "height" "18px"
                                                    , userIdColor userId
                                                        |> MyUi.colorToStyle
                                                        |> Html.Attributes.style "background-color"
                                                    , Html.Attributes.style "top" "0"
                                                    , Html.Attributes.style "left" "-2px"
                                                    ]
                                                    []
                                                ]
                                           ]
                                , lastPos = pos
                                }

                            _ ->
                                { activeSelections =
                                    case isStart of
                                        StartRange ->
                                            userId :: state.activeSelections

                                        EndRange ->
                                            List.Extra.remove userId state.activeSelections

                                        PointRange ->
                                            state.activeSelections
                                , html =
                                    state.html
                                        ++ [ case state.activeSelections of
                                                head :: rest ->
                                                    Html.span
                                                        [ mixColors (userIdColor head) (List.map userIdColor rest)
                                                            |> MyUi.colorToStyle
                                                            |> Html.Attributes.style "background-color"
                                                        ]
                                                        [ Html.text (String.slice state.lastPos pos text) ]

                                                [] ->
                                                    Html.text (String.slice state.lastPos pos text)
                                           ]
                                , lastPos = pos
                                }
                    )
                    { html = [ Html.text (String.slice 0 first.start text) ]
                    , activeSelections = []
                    , lastPos = first.start
                    }
                |> (\state ->
                        state.html ++ [ Html.text (String.slice state.lastPos (String.length text) text) ]
                   )

        [] ->
            [ Html.text text ]
