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
    , anchorHighlight
    , anchorHighlightHtmlClass
    , canRedo
    , canUndo
    , decodeWithTargetScreenPosition
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
    , undoButtonId
    , undoRedoButton
    , userColor
    , zoomButtonId
    , zoomCssOrigin
    , zoomLevel
    , zoomPointOffset
    )

import CssPixels exposing (CssPixels)
import Date exposing (Date)
import Discord
import Effect.Browser.Dom as Dom exposing (HtmlId)
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
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Lazy


type AnchorType
    = MessageAnchor ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor ThreadRoute Date


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Id FileId)
    | EmbedImageAnchor Int


{-| Points are in css pixels, relative to the top left corner of the anchor
element. Image anchors are an exception: there the points are in the image's
full resolution coordinate space so that drawings stay aligned when the image
is scaled down to fit smaller screens.
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
    | -- Carries the points that weren't sent in a ContinueStroke batch yet.
      -- They can't be sent as a separate ContinueStroke because two messages
      -- sent in the same frontend update aren't guaranteed to arrive in order.
      EndStroke (List ( Float, Float ))
    | UndoStroke
    | RedoStroke


type Msg
    = MouseDown Float Float
    | MouseMoved Float Float
    | MouseUp
    | PressedUndo
    | PressedRedo
    | PressedZoom
    | -- The conversation container's viewport position and width, measured after
      -- toggling zoom on. Nothing if the measurement failed.
      GotZoomContainer (Maybe { x : Float, y : Float, width : Float })


type Model
    = NoSelectedAnchor
    | SelectedAnchor SelectedAnchorData


type alias SelectedAnchorData =
    { guildOrDmId : AnyGuildOrDmId
    , anchorType : AnchorType
    , -- Position of the anchor element in viewport coordinates, used to convert
      -- mouse positions into anchor relative points. Nothing while being measured.
      position : Point2d CssPixels ScreenCoordinate
    , -- How many anchor coordinate units one css pixel covers. This is 1 for most
      -- anchors but image anchors store points in the image's full resolution
      -- coordinates while the image might be displayed scaled down.
      pointScale : Float
    , stroke : Maybe ActiveStroke
    , -- Half the displayed size of the anchor element in css pixels. Used to zoom
      -- in on the center of the anchor rather than its top left corner.
      anchorHalfSize : ( Float, Float )
    , -- How much the conversation viewport is magnified around the anchor so the
      -- user can draw more precisely. 1 means no zoom.
      zoom : Float
    , -- The conversation container's viewport position and width, measured after
      -- toggling zoom on. Used to anchor the css transform on the right spot.
      -- Nothing until measured.
      zoomContainer : Maybe { x : Float, y : Float, width : Float }
    }


type alias ActiveStroke =
    { -- Anchor relative points that haven't been sent to the backend yet, newest first
      unsent : List ( Float, Float )
    }


init : Model
init =
    NoSelectedAnchor


initialAnchorSelection : AnyGuildOrDmId -> AnchorType -> Point2d CssPixels ScreenCoordinate -> ( Float, Float ) -> Float -> SelectedAnchorData
initialAnchorSelection guildOrDmId anchorType position anchorHalfSize pointScale =
    { guildOrDmId = guildOrDmId
    , anchorType = anchorType
    , position = position
    , pointScale = pointScale
    , stroke = Nothing
    , anchorHalfSize = anchorHalfSize
    , zoom = 1
    , zoomContainer = Nothing
    }


{-| How much the conversation viewport is magnified when the user toggles zoom on
while drawing.
-}
zoomLevel : Float
zoomLevel =
    2.5


{-| The point the zoom is anchored on, in css pixels relative to the anchor's top
left corner. The user icon sits on the left of a message and the timestamp on the
right, so they zoom in from the left and right edge of the conversation
respectively to stay on screen. Everything else zooms in on its center.
-}
zoomPointOffset : SelectedAnchorData -> ( Float, Float )
zoomPointOffset selected =
    let
        ( halfWidth, halfHeight ) =
            selected.anchorHalfSize

        anchor : { x : Float, y : Float }
        anchor =
            Point2d.unwrap selected.position
    in
    case ( selected.anchorType, selected.zoomContainer ) of
        ( MessageAnchor _ UserIconAnchor, Just container ) ->
            ( container.x - anchor.x, halfHeight )

        ( MessageAnchor _ TimestampAnchor, Just container ) ->
            ( container.x + container.width - anchor.x, halfHeight )

        _ ->
            ( halfWidth, halfHeight )


{-| The css transform-origin to magnify the conversation around, in css pixels
relative to the conversation container. Nothing until the container is measured.
-}
zoomCssOrigin : SelectedAnchorData -> Maybe ( Float, Float )
zoomCssOrigin selected =
    case selected.zoomContainer of
        Just container ->
            let
                anchor : { x : Float, y : Float }
                anchor =
                    Point2d.unwrap selected.position

                ( offsetX, offsetY ) =
                    zoomPointOffset selected
            in
            Just ( anchor.x - container.x + offsetX, anchor.y - container.y + offsetY )

        Nothing ->
            Nothing


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

        EndStroke remainingPoints ->
            case SeqDict.get userId drawing.inProgress of
                Just stroke ->
                    { drawing
                        | inProgress = SeqDict.remove userId drawing.inProgress
                        , finished =
                            { createdBy = userId
                            , points =
                                case List.Nonempty.fromList remainingPoints of
                                    Just remaining ->
                                        List.Nonempty.append stroke.points remaining
                                            |> nonemptyTake maxPointsPerStroke

                                    Nothing ->
                                        stroke.points
                            }
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


profileImageAnchorId : Id messageId -> HtmlId
profileImageAnchorId messageId =
    Dom.id ("drawAnchorProfile_" ++ Id.toString messageId)


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


overlayAttribute : (userId -> String) -> Drawing userId -> Element msg
overlayAttribute getColor drawing =
    case strokesFor drawing of
        [] ->
            Ui.none

        strokes ->
            List.map (\( createdBy, points ) -> strokeSvg 1 (getColor createdBy) points) strokes
                |> Html.div []
                |> Ui.html
                |> Ui.el
                    [ Ui.width (Ui.px 0)
                    , Ui.height (Ui.px 0)
                    , MyUi.htmlStyle "pointer-events" "none"
                    ]


{-| scale converts the stored stroke points into css pixels. For image anchors
the points are stored in the image's full resolution coordinates so this is
displayedWidth / fullResolutionWidth, which keeps drawings aligned with the
image when it's scaled down to fit smaller screens.
-}
imageAttachmentOverlays : Float -> (userId -> String) -> Drawing userId -> List (Html msg)
imageAttachmentOverlays scale getColor drawing =
    List.map
        (\( createdBy, points ) -> strokeSvg scale (getColor createdBy) points)
        (strokesFor drawing)


strokeSvg : Float -> String -> Nonempty ( Float, Float ) -> Html msg
strokeSvg scale color points =
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
            , Svg.Attributes.transform ("scale(" ++ String.fromFloat scale ++ ")")
            , -- Keep the stroke 3 css pixels wide regardless of how much the
              -- points are scaled
              Html.Attributes.attribute "vector-effect" "non-scaling-stroke"
            , Svg.Attributes.fill "none"
            , Svg.Attributes.stroke color
            , Svg.Attributes.strokeWidth "3"
            , Svg.Attributes.strokeLinecap "round"
            , Svg.Attributes.strokeLinejoin "round"
            ]
            []
        ]


inputOverlayId : HtmlId
inputOverlayId =
    Dom.id "drawing_inputOverlay"


undoButtonId : HtmlId
undoButtonId =
    Dom.id "drawing_undo"


redoButtonId : HtmlId
redoButtonId =
    Dom.id "drawing_redo"


zoomButtonId : HtmlId
zoomButtonId =
    Dom.id "drawing_zoom"


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


anchorHighlight :
    HtmlId
    -> (userId -> String)
    -> (Point2d CssPixels ScreenCoordinate -> ( Float, Float ) -> msg)
    -> Bool
    -> Drawing userId
    -> List (Ui.Attribute msg)
anchorHighlight htmlId userIdToColor onPress isSelectingAnchor drawings =
    [ Ui.Events.on "click" (Json.Decode.map2 onPress decodeWithTargetScreenPosition decodeTargetHalfSize)
    , Dom.idToString htmlId |> Ui.id
    , Ui.Lazy.lazy2 overlayAttribute userIdToColor drawings |> Ui.inFront
    , Ui.width Ui.shrink
    ]
        ++ (if isSelectingAnchor then
                [ Ui.Anim.hovered
                    (Ui.Anim.ms 10)
                    [ Ui.Anim.backgroundColor (Ui.rgba 96 165 250 0.3)
                    , Ui.Anim.outlineColor (Ui.rgba 96 165 250 1)
                    ]
                , MyUi.htmlStyle "outline-style" "solid"
                , MyUi.htmlStyle "outline-width" "2px"
                , MyUi.htmlStyle "outline-color" "rgba(0,0,0,0)"
                , Ui.pointer
                ]

            else
                []
           )


{-| Same hover highlight as anchorHighlight but for elements rendered with plain
Html instead of elm-ui. The matching CSS rules live in MyUi.css.
-}
anchorHighlightHtmlClass : Html.Attribute msg
anchorHighlightHtmlClass =
    Html.Attributes.class "drawing-anchor-select"


{-| Half the displayed size of the clicked anchor element, read from the event's
currentTarget. Defaults to zero when the fields are missing (e.g. simulated test
clicks) which falls back to zooming in on the anchor's top left corner.
-}
decodeTargetHalfSize : Json.Decode.Decoder ( Float, Float )
decodeTargetHalfSize =
    Json.Decode.map2
        (\width height -> ( width / 2, height / 2 ))
        (currentTargetFloatWithDefault "offsetWidth")
        (currentTargetFloatWithDefault "offsetHeight")


currentTargetFloatWithDefault : String -> Json.Decode.Decoder Float
currentTargetFloatWithDefault fieldName =
    Json.Decode.oneOf
        [ Json.Decode.at [ "currentTarget", fieldName ] Json.Decode.float
        , Json.Decode.succeed 0
        ]


decodeWithTargetScreenPosition : Json.Decode.Decoder (Point2d CssPixels ScreenCoordinate)
decodeWithTargetScreenPosition =
    Json.Decode.map4
        (\clientX clientY offsetX offsetY ->
            Point2d.xy
                (CssPixels.cssPixels (clientX - offsetX))
                (CssPixels.cssPixels (clientY - offsetY))
        )
        (floatFieldWithDefault "clientX")
        (floatFieldWithDefault "clientY")
        (floatFieldWithDefault "offsetX")
        (floatFieldWithDefault "offsetY")


{-| Real mouse events always include the position fields but simulated click
events in tests might not.
-}
floatFieldWithDefault : String -> Json.Decode.Decoder Float
floatFieldWithDefault fieldName =
    Json.Decode.oneOf [ Json.Decode.field fieldName Json.Decode.float, Json.Decode.succeed 0 ]


undoRedoButton : HtmlId -> Msg -> String -> Bool -> Element Msg
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
