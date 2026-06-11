module Drawing exposing
    ( ActiveStroke
    , AnchorType(..)
    , Drawing
    , LocalChange(..)
    , MessageAnchor(..)
    , Model(..)
    , Msg(..)
    , SelectedAnchorData
    , Stroke
    , anchorHighlightStyle
    , canRedo
    , canUndo
    , dateDividerOverlay
    , discordUserColor
    , emptyDrawing
    , handleLocalChange
    , imageAttachmentOverlays
    , init
    , initialAnchorSelection
    , inputOverlay
    , inputOverlayId
    , profileImageAnchorId
    , redoButtonId
    , resetAnchor
    , timestampOverlays
    , undoButtonId
    , undoRedoButton
    , userColor
    , userIconOverlay
    )

import CssPixels exposing (CssPixels)
import Date exposing (Date)
import Discord
import Effect.Browser.Dom as Dom
import FileStatus exposing (FileId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (AnyGuildOrDmId, Id, ThreadRoute, ThreadRouteWithMessage, UserId)
import Json.Decode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import Point2d exposing (Point2d)
import SeqDict exposing (SeqDict)
import Svg
import Svg.Attributes
import Touch exposing (ScreenCoordinate)
import Ui exposing (Element)
import Ui.Font


type AnchorType
    = MessageAnchor ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor ThreadRoute Date


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Id FileId)


{-| Points are in css pixels, relative to the top left corner of the anchor element.
-}
type alias Stroke =
    { points : Nonempty ( Float, Float )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : Nonempty ( Float, Float )
            }
    , inProgress : SeqDict userId Stroke
    , -- Per-user redo stacks, most recently undone stroke first
      undone : SeqDict userId (List Stroke)
    }


emptyDrawing : Drawing userId
emptyDrawing =
    { finished = [], inProgress = SeqDict.empty, undone = SeqDict.empty }


type LocalChange
    = StartStroke ( Float, Float )
    | ContinueStroke (Nonempty ( Float, Float ))
    | EndStroke
    | UndoStroke
    | RedoStroke


type Msg
    = MouseDown Float Float
    | MouseMoved Float Float
    | MouseUp
    | PressedUndo
    | PressedRedo


type Model
    = NoSelectedAnchor
    | SelectedAnchor SelectedAnchorData


type alias SelectedAnchorData =
    { guildOrDmId : AnyGuildOrDmId
    , anchorType : AnchorType
    , -- Position of the anchor element in viewport coordinates, used to convert
      -- mouse positions into anchor relative points. Nothing while being measured.
      position : Point2d CssPixels ScreenCoordinate
    , stroke : Maybe ActiveStroke
    }


type alias ActiveStroke =
    { -- Anchor relative points that haven't been sent to the backend yet, newest first
      unsent : List ( Float, Float )
    }


init : Model
init =
    NoSelectedAnchor


initialAnchorSelection : AnyGuildOrDmId -> AnchorType -> Point2d CssPixels ScreenCoordinate -> SelectedAnchorData
initialAnchorSelection guildOrDmId anchorType position =
    { guildOrDmId = guildOrDmId
    , anchorType = anchorType
    , position = position
    , stroke = Nothing
    }


maxFinishedStrokes : Int
maxFinishedStrokes =
    200


maxPointsPerStroke : Int
maxPointsPerStroke =
    4000


{-| Resizing the window can move the anchor element and its position was only
captured when the user clicked on it, so the user has to pick an anchor again.
-}
resetAnchor : Model -> Model
resetAnchor _ =
    NoSelectedAnchor


handleLocalChange : userId -> LocalChange -> Drawing userId -> Drawing userId
handleLocalChange userId change drawing =
    case change of
        StartStroke point ->
            { drawing
                | inProgress =
                    SeqDict.insert
                        userId
                        { points = Nonempty point [] }
                        drawing.inProgress
                , -- Starting a new stroke clears anything that could be redone
                  undone = SeqDict.remove userId drawing.undone
            }

        ContinueStroke points ->
            case SeqDict.get userId drawing.inProgress of
                Just stroke ->
                    { drawing
                        | inProgress =
                            SeqDict.insert
                                userId
                                { stroke
                                    | points =
                                        List.Nonempty.append stroke.points points
                                            |> nonemptyTake maxPointsPerStroke
                                }
                                drawing.inProgress
                    }

                Nothing ->
                    drawing

        EndStroke ->
            case SeqDict.get userId drawing.inProgress of
                Just stroke ->
                    { drawing
                        | inProgress = SeqDict.remove userId drawing.inProgress
                        , finished =
                            { createdBy = userId, points = stroke.points }
                                :: drawing.finished
                                |> List.take maxFinishedStrokes
                    }

                Nothing ->
                    drawing

        UndoStroke ->
            case List.Extra.splitWhen (\finished -> finished.createdBy == userId) drawing.finished of
                Just ( before, undoneStroke :: after ) ->
                    { drawing
                        | finished = before ++ after
                        , undone =
                            SeqDict.update
                                userId
                                (\maybe ->
                                    { points = undoneStroke.points }
                                        :: Maybe.withDefault [] maybe
                                        |> Just
                                )
                                drawing.undone
                    }

                _ ->
                    drawing

        RedoStroke ->
            case SeqDict.get userId drawing.undone of
                Just (stroke :: rest) ->
                    { drawing
                        | finished =
                            { createdBy = userId, points = stroke.points }
                                :: drawing.finished
                        , undone = SeqDict.insert userId rest drawing.undone
                    }

                _ ->
                    drawing


canUndo : userId -> Drawing userId -> Bool
canUndo userId drawing =
    List.any (\finished -> finished.createdBy == userId) drawing.finished


canRedo : userId -> Drawing userId -> Bool
canRedo userId drawing =
    case SeqDict.get userId drawing.undone of
        Just (_ :: _) ->
            True

        _ ->
            False


nonemptyTake : Int -> Nonempty a -> Nonempty a
nonemptyTake amount (Nonempty head rest) =
    Nonempty head (List.take (amount - 1) rest)


profileImageAnchorId : Dom.HtmlId -> Id messageId -> Dom.HtmlId
profileImageAnchorId htmlIdPrefix messageId =
    Dom.id (Dom.idToString htmlIdPrefix ++ "_drawAnchorProfile_" ++ Id.toString messageId)


userColor : Id UserId -> String
userColor userId =
    let
        colors : List String
        colors =
            [ "#ff5252"
            , "#40c4ff"
            , "#69f0ae"
            , "#ffd740"
            , "#e040fb"
            , "#ffab40"
            , "#64ffda"
            , "#ff80ab"
            ]

        index : Int
        index =
            modBy (List.length colors) (Id.toInt userId * 31)
    in
    List.drop index colors |> List.head |> Maybe.withDefault "#ff5252"


discordUserColor : Discord.Id Discord.UserId -> String
discordUserColor userId =
    let
        colors : List String
        colors =
            [ "#ff5252"
            , "#40c4ff"
            , "#69f0ae"
            , "#ffd740"
            , "#e040fb"
            , "#ffab40"
            , "#64ffda"
            , "#ff80ab"
            ]

        index : Int
        index =
            String.foldl (\char total -> total * 31 + Char.toCode char) 0 (Discord.idToString userId)
                |> modBy (List.length colors)
    in
    List.drop index colors |> List.head |> Maybe.withDefault "#ff5252"


{-| Finished and in-progress strokes that are attached to the given anchor type.
-}
strokesFor : Drawing userId -> List ( userId, Nonempty ( Float, Float ) )
strokesFor drawing =
    List.map (\finished -> ( finished.createdBy, finished.points )) drawing.finished
        ++ List.map (\( createdBy, stroke ) -> ( createdBy, stroke.points )) (SeqDict.toList drawing.inProgress)


{-| Strokes anchored to the profile image of a message, placed in front of it
so they move together with the profile image. The svg has no size of its own
(overflow is visible) and ignores pointer events so it never blocks
interactions with the message below it.
-}
userIconOverlay : (userId -> String) -> Drawing userId -> Ui.Attribute msg
userIconOverlay =
    overlayAttribute


{-| Strokes anchored to the date divider that is shown above the first message of a day.
-}
dateDividerOverlay : (userId -> String) -> Drawing userId -> Ui.Attribute msg
dateDividerOverlay =
    overlayAttribute


overlayAttribute : (userId -> String) -> Drawing userId -> Ui.Attribute msg
overlayAttribute getColor drawing =
    case strokesFor drawing of
        [] ->
            Ui.noAttr

        strokes ->
            List.map (\( createdBy, points ) -> strokeSvg (getColor createdBy) points) strokes
                |> Html.div []
                |> Ui.html
                |> Ui.el
                    [ Ui.width (Ui.px 0)
                    , Ui.height (Ui.px 0)
                    , MyUi.htmlStyle "pointer-events" "none"
                    ]
                |> Ui.inFront


{-| Strokes anchored to the timestamp of a message. These are added as children
of the timestamp element (which is position:relative) so they move together
with the timestamp.
-}
timestampOverlays : (userId -> String) -> Drawing userId -> List (Html msg)
timestampOverlays getColor drawing =
    List.map
        (\( createdBy, points ) -> strokeSvg (getColor createdBy) points)
        (strokesFor drawing)


imageAttachmentOverlays : (userId -> String) -> Drawing userId -> List (Html msg)
imageAttachmentOverlays getColor drawing =
    List.map
        (\( createdBy, points ) -> strokeSvg (getColor createdBy) points)
        (strokesFor drawing)


strokeSvg : String -> Nonempty ( Float, Float ) -> Html msg
strokeSvg color points =
    Svg.svg
        [ Svg.Attributes.width "1"
        , Svg.Attributes.height "1"
        , Svg.Attributes.style "position:absolute;left:0;top:0;overflow:visible;pointer-events:none;display:block"
        ]
        [ Svg.polyline
            [ List.Nonempty.toList points
                |> List.map
                    (\( x, y ) ->
                        String.fromFloat x ++ "," ++ String.fromFloat y
                    )
                |> String.join " "
                |> Svg.Attributes.points
            , Svg.Attributes.fill "none"
            , Svg.Attributes.stroke color
            , Svg.Attributes.strokeWidth "3"
            , Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            ]
            []
        ]


inputOverlayId : Dom.HtmlId
inputOverlayId =
    Dom.id "drawing_inputOverlay"


undoButtonId : Dom.HtmlId
undoButtonId =
    Dom.id "drawing_undo"


redoButtonId : Dom.HtmlId
redoButtonId =
    Dom.id "drawing_redo"


{-| Transparent overlay that captures mouse events while the user is drawing.
-}
inputOverlay : Bool -> (Msg -> msg) -> Element msg
inputOverlay strokeActive toMsg =
    Html.div
        ([ Html.Attributes.id (Dom.idToString inputOverlayId)
         , Html.Attributes.style "position" "absolute"
         , Html.Attributes.style "left" "0"
         , Html.Attributes.style "top" "0"
         , Html.Attributes.style "width" "100%"
         , Html.Attributes.style "height" "100%"
         , Html.Attributes.style "cursor" "crosshair"
         , Html.Events.on
            "mousedown"
            (Json.Decode.field "button" Json.Decode.int
                |> Json.Decode.andThen
                    (\button ->
                        if button == 0 then
                            decodeMousePosition MouseDown

                        else
                            Json.Decode.fail "Only drawing with the primary mouse button is supported"
                    )
            )
         ]
            ++ (if strokeActive then
                    [ Html.Events.on "mousemove" (decodeMousePosition MouseMoved)
                    , Html.Events.on "mouseup" (Json.Decode.succeed MouseUp)
                    , Html.Events.on "mouseleave" (Json.Decode.succeed MouseUp)
                    ]

                else
                    []
               )
        )
        []
        |> Html.map toMsg
        |> Ui.html
        |> Ui.el [ Ui.height Ui.fill ]


decodeMousePosition : (Float -> Float -> Msg) -> Json.Decode.Decoder Msg
decodeMousePosition toMsg =
    Json.Decode.map2
        toMsg
        (Json.Decode.field "clientX" Json.Decode.float)
        (Json.Decode.field "clientY" Json.Decode.float)


{-| While picking an anchor, highlights valid anchor elements when the cursor
hovers over them.
-}
anchorHighlightStyle : Element msg
anchorHighlightStyle =
    Html.node
        "style"
        []
        [ Html.text
            ("[id*='drawAnchorProfile']:hover, [id^='guild_messageTimestamp']:hover, [id^='spoiler_'][id*='_image_']:hover, [id^='guild_dateDivider']:hover {"
                ++ "outline: 3px solid rgba(96, 165, 250, 0.8);"
                ++ "outline-offset: 2px;"
                ++ "background-color: rgba(96, 165, 250, 0.3);"
                ++ "border-radius: 4px;"
                ++ "cursor: pointer;"
                ++ "}"
            )
        ]
        |> Ui.html
        |> Ui.el [ Ui.width (Ui.px 0), Ui.height (Ui.px 0) ]


undoRedoButton : Dom.HtmlId -> Msg -> String -> Bool -> Element Msg
undoRedoButton htmlId onPress label isEnabled =
    MyUi.elButton
        htmlId
        onPress
        [ Ui.width Ui.shrink
        , Ui.paddingXY 12 4
        , Ui.rounded 4
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.background
            (if isEnabled then
                MyUi.background2

             else
                MyUi.background1
            )
        , Ui.Font.color
            (if isEnabled then
                MyUi.font1

             else
                MyUi.font3
            )
        ]
        (Ui.text label)
