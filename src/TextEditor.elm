module TextEditor exposing
    ( LocalChange(..)
    , LocalState
    , Model
    , Msg
    , ServerChange
    , backendChangeUpdate
    , changeUpdate
    , getEditorState
    , init
    , initLocalState
    , inputId
    , insertTextHelper
    , insertTextHelperInverse
    , isPress
    , localChangeUpdate
    , update
    , view
    )

import Array exposing (Array)
import Color exposing (Color)
import Color.Manipulate
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
import String.Extra
import String.Nonempty
import Ui exposing (Element)
import Ui.Font


type Msg
    = TypedText String
    | MovedCursor Range
    | PressedReset
    | UndoChange
    | RedoChange


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Range


type ServerChange
    = Server_EditChange (Id UserId) EditChange
    | Server_Reset
    | Server_Undo (Id UserId)
    | Server_Redo (Id UserId)
    | Server_MovedCursor (Id UserId) Range


type EditChange
    = Edit_TypedText Range String


type alias Model =
    {}


type alias LocalState =
    { undoPoint : SeqDict (Id UserId) Int
    , history : Array ( Id UserId, EditChange )
    , cursorPosition : SeqDict (Id UserId) Range
    }


init : Model
init =
    {}


initLocalState : LocalState
initLocalState =
    { undoPoint = SeqDict.empty, history = Array.empty, cursorPosition = SeqDict.empty }


type alias EditorState =
    { text : String
    }


initEditorState : EditorState
initEditorState =
    { text = "" }


getEditorState : LocalState -> EditorState
getEditorState local =
    Array.foldl
        (\( changeBy, change ) ( index, skipped, state ) ->
            let
                isSkipped : Bool
                isSkipped =
                    case SeqDict.get changeBy local.undoPoint of
                        Just undoPoint ->
                            undoPoint < index

                        Nothing ->
                            True
            in
            if isSkipped then
                ( index + 1
                , change :: skipped
                , state
                )

            else
                ( index + 1
                , skipped
                , case change of
                    Edit_TypedText range text ->
                        insertText (List.foldl addEditAdjustRange range skipped) text state
                  --insertText range text state
                )
        )
        ( 0, [], initEditorState )
        local.history
        |> (\( _, _, a ) -> a)


update : Id UserId -> Msg -> Model -> LocalState -> ( Model, Maybe LocalChange )
update currentUserId msg model local =
    case msg of
        TypedText text ->
            let
                editorState =
                    getEditorState local
            in
            case SeqDict.get currentUserId local.cursorPosition of
                Just range ->
                    let
                        lengthDiff : Int
                        lengthDiff =
                            String.length text - String.length editorState.text
                    in
                    ( model
                    , if RichText.rangeSize range == 0 && lengthDiff < 0 then
                        Edit_TypedText { range | start = range.start + lengthDiff } ""
                            |> Local_EditChange
                            |> Just

                      else
                        String.slice range.start (range.start + lengthDiff + RichText.rangeSize range) text
                            |> Edit_TypedText range
                            |> Local_EditChange
                            |> Just
                    )

                Nothing ->
                    ( model, Nothing )

        MovedCursor range ->
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
            ( model, Just Local_Reset )

        UndoChange ->
            ( model, Just Local_Undo )

        RedoChange ->
            ( model, Just Local_Redo )


localChangeUpdate : Id UserId -> LocalChange -> LocalState -> LocalState
localChangeUpdate currentUserId change local =
    case change of
        Local_EditChange change2 ->
            addEdit currentUserId change2 local

        Local_Reset ->
            initLocalState

        Local_Undo ->
            undoChange currentUserId local

        Local_Redo ->
            redoChange currentUserId local

        Local_MovedCursor range ->
            moveCursor currentUserId range local


changeUpdate : ServerChange -> LocalState -> LocalState
changeUpdate change local =
    case change of
        Server_EditChange changeBy change2 ->
            addEdit changeBy change2 local

        Server_Reset ->
            initLocalState

        Server_Undo userId ->
            undoChange userId local

        Server_Redo userId ->
            redoChange userId local

        Server_MovedCursor userId range ->
            moveCursor userId range local


moveCursor : Id UserId -> Range -> LocalState -> LocalState
moveCursor userId range local =
    { local | cursorPosition = SeqDict.insert userId range local.cursorPosition }


undoChange : Id UserId -> LocalState -> LocalState
undoChange userId local =
    { local
        | undoPoint =
            SeqDict.update
                userId
                (\maybe ->
                    case maybe of
                        Just index ->
                            getNextUndoPoint userId (index - 1) local.history

                        Nothing ->
                            Nothing
                )
                local.undoPoint
    }


redoChange : Id UserId -> LocalState -> LocalState
redoChange userId local =
    let
        oldRedoPoint =
            SeqDict.get userId local.undoPoint |> Maybe.withDefault -1
    in
    case getNextRedoPoint userId (oldRedoPoint + 1) local.history of
        Just ( redoPoint, edit ) ->
            { local
                | undoPoint = SeqDict.insert userId redoPoint local.undoPoint
                , cursorPosition = SeqDict.map (\_ range -> addEditAdjustRange edit range) local.cursorPosition
            }

        Nothing ->
            local


getNextUndoPoint : Id UserId -> Int -> Array ( Id UserId, EditChange ) -> Maybe Int
getNextUndoPoint userId index history =
    case Array.get index history of
        Just ( changeBy, edit ) ->
            if changeBy == userId then
                Just index

            else
                getNextUndoPoint userId (index - 1) history

        Nothing ->
            Nothing


getNextRedoPoint : Id UserId -> Int -> Array ( Id UserId, EditChange ) -> Maybe ( Int, EditChange )
getNextRedoPoint userId index history =
    case Array.get index history of
        Just ( changeBy, edit ) ->
            if changeBy == userId then
                Just ( index, edit )

            else
                getNextRedoPoint userId (index + 1) history

        Nothing ->
            Nothing


addEdit : Id UserId -> EditChange -> LocalState -> LocalState
addEdit changeBy change local =
    let
        undoPoint : Int
        undoPoint =
            SeqDict.get changeBy local.undoPoint |> Maybe.withDefault -1

        kept =
            Array.slice (undoPoint + 1) (Array.length local.history) local.history
                |> Array.filter (\( a, _ ) -> a /= changeBy)

        removed : List Int
        removed =
            Array.slice (undoPoint + 1) (Array.length local.history) local.history
                |> Array.toList
                |> List.indexedMap
                    (\index ( a, _ ) ->
                        if a == changeBy then
                            Just (index + (undoPoint + 1))

                        else
                            Nothing
                    )
                |> List.filterMap identity

        history : Array ( Id UserId, EditChange )
        history =
            Array.append (Array.slice 0 (undoPoint + 1) local.history) kept |> Array.push ( changeBy, change )
    in
    { local
        | history = history
        , undoPoint =
            SeqDict.insert changeBy
                (Array.length history - 1)
                (SeqDict.map
                    (\_ undoPoint2 ->
                        undoPoint2 - List.Extra.count (\index -> index < undoPoint2) removed
                    )
                    local.undoPoint
                )
        , cursorPosition = SeqDict.map (\_ range -> addEditAdjustRange change range) local.cursorPosition
    }


addEditAdjustRange : EditChange -> Range -> Range
addEditAdjustRange change range =
    case change of
        Edit_TypedText insertionRange string ->
            let
                insertCount =
                    String.length string
            in
            insertTextHelper insertCount insertionRange range


{-| Does the inverse of insertTextHelper

    let
        input =
            { start = 8, end = 11 }

        output =
            insertTextHelper 5 { start = 6, end = 10 } input
    in
    input == insertTextHelperInverse 5 { start = 6, end = 10 } output

-}
insertTextHelperInverse : Int -> Range -> Range -> Range
insertTextHelperInverse insertCount removeRange output =
    let
        size : Int
        size =
            RichText.rangeSize removeRange

        -- If output moved due to insertion, determine where input was
        inputStart : Int
        inputStart =
            if removeRange.start < output.start then
                -- Output was shifted by insertCount - size
                output.start + size - insertCount

            else
                output.start

        inputEnd : Int
        inputEnd =
            if removeRange.start <= output.end then
                -- Output was shifted by insertCount - size
                output.end + size - insertCount

            else
                output.end

        -- Now check if input was clipped by removeRange
        wasStartClipped : Bool
        wasStartClipped =
            removeRange.start <= inputStart && inputStart < removeRange.end

        wasEndClipped : Bool
        wasEndClipped =
            removeRange.start < inputEnd && inputEnd <= removeRange.end
    in
    { start =
        if wasStartClipped then
            removeRange.start

        else
            inputStart
    , end =
        if wasEndClipped then
            removeRange.start

        else
            inputEnd
    }


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


insertText : Range -> String -> EditorState -> EditorState
insertText insertionRange text local =
    { local
        | text = String.Extra.replaceSlice text (max 0 insertionRange.start) insertionRange.end local.text
    }


backendChangeUpdate :
    Id UserId
    -> LocalChange
    -> LocalState
    -> ( LocalState, ServerChange )
backendChangeUpdate currentUserId change local =
    case change of
        Local_EditChange change2 ->
            ( addEdit currentUserId change2 local
            , Server_EditChange currentUserId change2
            )

        Local_Reset ->
            ( initLocalState, Server_Reset )

        Local_Undo ->
            ( undoChange currentUserId local, Server_Undo currentUserId )

        Local_Redo ->
            ( redoChange currentUserId local, Server_Redo currentUserId )

        Local_MovedCursor range ->
            ( moveCursor currentUserId range local, Server_MovedCursor currentUserId range )


inputId : HtmlId
inputId =
    Dom.id "textEditor_input"


view : Bool -> Id UserId -> LocalState -> Element Msg
view isMobile currentUserId local =
    let
        editorState : EditorState
        editorState =
            getEditorState local
    in
    Ui.row
        [ Ui.height Ui.fill
        , MyUi.htmlStyle "padding" (MyUi.insetTop ++ " 0 " ++ MyUi.insetBottom ++ " 0")
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
                , MyUi.htmlStyle "transform" ("translateY(" ++ MyUi.insetTop ++ ")")
                ]
                (Ui.text "Reset")
            )
        , Ui.contentTop
        ]
        [ Ui.column
            [ Ui.background MyUi.background1, Ui.width (Ui.px 200), Ui.scrollable, Ui.Font.size 14 ]
            (Array.toList local.history
                |> List.indexedMap
                    (\index ( changeBy, edit ) ->
                        let
                            color =
                                userIdColor changeBy
                        in
                        Ui.el
                            [ Ui.background color
                            , if SeqDict.get changeBy local.undoPoint == Just index then
                                Ui.borderColor (Color.Manipulate.lighten 0.4 color)

                              else
                                Ui.borderColor color
                            , Ui.borderWith { left = 4, right = 0, top = 0, bottom = 0 }
                            , Ui.paddingWith { right = 4, left = 0, top = 0, bottom = 0 }
                            , Ui.clipWithEllipsis
                            ]
                            (Ui.text
                                (case edit of
                                    Edit_TypedText range string ->
                                        "Typed \"" ++ string ++ "\""
                                )
                            )
                    )
            )
        , textarea local currentUserId "Nothing written yet..." editorState
            |> Ui.html
            |> Ui.el []
        ]


isPress : Msg -> Bool
isPress msg =
    case msg of
        TypedText string ->
            False

        MovedCursor range ->
            False

        PressedReset ->
            True

        UndoChange ->
            False

        RedoChange ->
            False


selectionDecoder : Json.Decode.Decoder Range
selectionDecoder =
    Json.Decode.map2 (\start end -> Range (min start end) (max start end))
        (Json.Decode.at [ "target", "selectionStart" ] Json.Decode.int)
        (Json.Decode.at [ "target", "selectionEnd" ] Json.Decode.int)


textarea : LocalState -> Id UserId -> String -> EditorState -> Html Msg
textarea local currentUserId placeholderText editorState =
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "min-height" "min-content"
        , Html.Attributes.style "width" "100%"
        , Html.Attributes.style "height" "fit-content"
        ]
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
            , Html.Attributes.value editorState.text
            , Html.Events.on "selectionchange" (Json.Decode.map MovedCursor selectionDecoder)
            , Dom.idToAttribute inputId
            , Html.Events.preventDefaultOn
                "keydown"
                (Json.Decode.map3
                    (\a b c -> ( a, b, c ))
                    (Json.Decode.field "key" Json.Decode.string)
                    (Json.Decode.field "ctrlKey" Json.Decode.bool)
                    (Json.Decode.field "metaKey" Json.Decode.bool)
                    |> Json.Decode.andThen
                        (\( key, ctrlHeld, metaHeld ) ->
                            if (ctrlHeld || metaHeld) && key == "z" then
                                Json.Decode.succeed ( UndoChange, True )

                            else if (ctrlHeld || metaHeld) && key == "y" then
                                Json.Decode.succeed ( RedoChange, True )

                            else
                                Json.Decode.fail ""
                        )
                )
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
                (if editorState.text == "" then
                    "rgb(180,180,180)"

                 else
                    "rgb(255,255,255)"
                )
            ]
            (case String.Nonempty.fromString editorState.text of
                Just nonempty ->
                    highlightText editorState.text currentUserId editorState local ++ [ Html.text "\n" ]

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
            Color.rgb255 158 0 0

        1 ->
            Color.rgb255 0 127 0

        2 ->
            Color.rgb255 115 115 0

        3 ->
            Color.rgb255 0 121 121

        4 ->
            Color.rgb255 118 0 118

        _ ->
            Color.rgb255 147 105 105


mixColors : Color -> List Color -> Html.Attribute msg
mixColors first rest =
    Html.Attributes.style
        "background"
        ("repeating-linear-gradient(45deg"
            ++ String.concat
                (List.indexedMap
                    (\index color ->
                        let
                            colorText =
                                Color.toCssString color

                            offset0 =
                                " " ++ String.fromInt (index * 6) ++ "px,"

                            offset1 =
                                " " ++ String.fromInt ((index + 1) * 6) ++ "px"
                        in
                        if index == 0 then
                            "," ++ colorText ++ "," ++ colorText ++ offset1

                        else
                            "," ++ colorText ++ offset0 ++ colorText ++ offset1
                    )
                    (first :: rest)
                )
            ++ ")"
        )


highlightText : String -> Id UserId -> EditorState -> LocalState -> List (Html msg)
highlightText text currentUserId editorState local =
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
