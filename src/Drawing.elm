module Drawing exposing
    ( ActiveStroke
    , Anchor
    , AnchorType(..)
    , ChannelDrawing
    , LocalChange(..)
    , Model(..)
    , Msg(..)
    , SelectedAnchorData
    , Stroke
    , anchorDomId
    , anchorDomIdFallback
    , anchorHighlightStyle
    , canRedo
    , canUndo
    , decodePickAnchor
    , emptyChannelDrawing
    , handleLocalChange
    , init
    , initialAnchorSelection
    , inputOverlay
    , inputOverlayId
    , pickAreaId
    , profileImageAnchorId
    , redoButtonId
    , resetAnchor
    , timestampAnchorId
    , undoButtonId
    , undoRedoButton
    , wrapMessageView
    )

import Effect.Browser.Dom as Dom
import FileStatus exposing (FileId)
import Html
import Html.Attributes
import Html.Events
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute, ThreadRouteWithMessage, UserId)
import Json.Decode
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import MyUi
import SeqDict exposing (SeqDict)
import Svg
import Svg.Attributes
import Ui exposing (Element)
import Ui.Font


type AnchorType
    = ProfileImageAnchor
    | TimestampAnchor
    | AttachmentAnchor (Id FileId)


type alias Anchor =
    { messageId : Id ChannelMessageId
    , anchorType : AnchorType
    }


{-| Points are in css pixels, relative to the top left corner of the anchor element.
-}
type alias Stroke =
    { anchor : AnchorType
    , points : Nonempty ( Float, Float )
    }


type alias ChannelDrawing userId =
    { finished : List { createdBy : userId, stroke : Stroke }
    , inProgress : SeqDict userId Stroke
    , -- Per-user redo stacks, most recently undone stroke first
      undone : SeqDict userId (List Stroke)
    }


emptyChannelDrawing : ChannelDrawing userId
emptyChannelDrawing =
    { finished = [], inProgress = SeqDict.empty, undone = SeqDict.empty }


type LocalChange
    = StartStroke AnchorType ( Float, Float )
    | ContinueStroke (Nonempty ( Float, Float ))
    | EndStroke
    | UndoStroke
    | RedoStroke


type Msg
    = PickedAnchor (Maybe Anchor)
    | GotAnchorElement Anchor (Result Dom.Error { anchor : Dom.Element, container : Dom.Element })
    | MouseDown Float Float
    | MouseMoved Float Float
    | MouseUp
    | PressedUndo
    | PressedRedo


type Model
    = NoSelectedAnchor
    | SelectedAnchor SelectedAnchorData


type alias SelectedAnchorData =
    { guildOrDmId : GuildOrDmId
    , threadRoute : ThreadRouteWithMessage
    , anchorType : AnchorType
    , -- Position of the anchor element in viewport coordinates, used to convert
      -- mouse positions into anchor relative points. Nothing while being measured.
      position : Maybe ( Float, Float )
    , stroke : Maybe ActiveStroke
    }


type alias ActiveStroke =
    { -- Anchor relative points that haven't been sent to the backend yet, newest first
      unsent : List ( Float, Float )
    }


init : Model
init =
    NoSelectedAnchor


initialAnchorSelection : GuildOrDmId -> ThreadRouteWithMessage -> AnchorType -> SelectedAnchorData
initialAnchorSelection guildOrDmId threadRoute anchorType =
    { guildOrDmId = guildOrDmId
    , threadRoute = threadRoute
    , anchorType = anchorType
    , position = Nothing
    , stroke = Nothing
    }


maxFinishedStrokes : Int
maxFinishedStrokes =
    200


maxPointsPerStroke : Int
maxPointsPerStroke =
    4000


resetAnchor : Model -> Model
resetAnchor model =
    case model of
        NoSelectedAnchor ->
            model

        SelectedAnchor data ->
            SelectedAnchor { data | position = Nothing, stroke = Nothing }


handleLocalChange : userId -> LocalChange -> ChannelDrawing userId -> ChannelDrawing userId
handleLocalChange userId change drawing =
    case change of
        StartStroke anchor point ->
            { drawing
                | inProgress =
                    SeqDict.insert
                        userId
                        { anchor = anchor, points = Nonempty point [] }
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
                            { createdBy = userId, stroke = stroke }
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
                                    undoneStroke.stroke
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
                        | finished = { createdBy = userId, stroke = stroke } :: drawing.finished
                        , undone = SeqDict.insert userId rest drawing.undone
                    }

                _ ->
                    drawing


canUndo : userId -> ChannelDrawing userId -> Bool
canUndo userId drawing =
    List.any (\finished -> finished.createdBy == userId) drawing.finished


canRedo : userId -> ChannelDrawing userId -> Bool
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


timestampAnchorId : Dom.HtmlId -> Id messageId -> Dom.HtmlId
timestampAnchorId htmlIdPrefix messageId =
    Dom.id (Dom.idToString htmlIdPrefix ++ "_drawAnchorTimestamp_" ++ Id.toString messageId)


channelHtmlIdPrefix : String
channelHtmlIdPrefix =
    "spoiler"


anchorDomId : Anchor -> Dom.HtmlId
anchorDomId anchor =
    case anchor.anchorType of
        ProfileImageAnchor ->
            profileImageAnchorId (Dom.id channelHtmlIdPrefix) anchor.messageId

        TimestampAnchor ->
            timestampAnchorId (Dom.id channelHtmlIdPrefix) anchor.messageId

        AttachmentAnchor fileId ->
            Dom.id
                (channelHtmlIdPrefix
                    ++ "_"
                    ++ Id.toString anchor.messageId
                    ++ "_image_"
                    ++ Id.toString fileId
                )


{-| Attachments that aren't images use a different DOM id, so if the primary id
isn't found this one should be tried instead.
-}
anchorDomIdFallback : Anchor -> Maybe Dom.HtmlId
anchorDomIdFallback anchor =
    case anchor.anchorType of
        AttachmentAnchor fileId ->
            Dom.id
                (channelHtmlIdPrefix
                    ++ "_"
                    ++ Id.toString anchor.messageId
                    ++ "_file_"
                    ++ Id.toString fileId
                )
                |> Just

        ProfileImageAnchor ->
            Nothing

        TimestampAnchor ->
            Nothing


anchorFromDomId : String -> Maybe Anchor
anchorFromDomId domId =
    case String.split "_" domId of
        [ prefix, "drawAnchorProfile", messageId ] ->
            if prefix == channelHtmlIdPrefix then
                parseAnchor messageId ProfileImageAnchor

            else
                Nothing

        [ prefix, "drawAnchorTimestamp", messageId ] ->
            if prefix == channelHtmlIdPrefix then
                parseAnchor messageId TimestampAnchor

            else
                Nothing

        [ prefix, messageId, "image", fileId ] ->
            if prefix == channelHtmlIdPrefix then
                String.toInt fileId
                    |> Maybe.andThen (\int -> parseAnchor messageId (AttachmentAnchor (Id.fromInt int)))

            else
                Nothing

        [ prefix, messageId, "file", fileId ] ->
            if prefix == channelHtmlIdPrefix then
                String.toInt fileId
                    |> Maybe.andThen (\int -> parseAnchor messageId (AttachmentAnchor (Id.fromInt int)))

            else
                Nothing

        _ ->
            Nothing


parseAnchor : String -> AnchorType -> Maybe Anchor
parseAnchor messageIdText anchorType =
    case String.toInt messageIdText of
        Just int ->
            Just { messageId = Id.fromInt int, anchorType = anchorType }

        Nothing ->
            Nothing


{-| Walks up from the clicked element looking for something that can be used as
a drawing anchor (profile image, timestamp, or attached file/image).
-}
decodePickAnchor : Json.Decode.Decoder (Maybe Anchor)
decodePickAnchor =
    Json.Decode.field "target" (walkUpForAnchor 30)


walkUpForAnchor : Int -> Json.Decode.Decoder (Maybe Anchor)
walkUpForAnchor depth =
    if depth <= 0 then
        Json.Decode.succeed Nothing

    else
        Json.Decode.oneOf
            [ Json.Decode.field "id" Json.Decode.string
                |> Json.Decode.andThen
                    (\id ->
                        case anchorFromDomId id of
                            Just anchor ->
                                Json.Decode.succeed (Just anchor)

                            Nothing ->
                                Json.Decode.fail "Not an anchor"
                    )
            , Json.Decode.field "parentElement" (Json.Decode.lazy (\() -> walkUpForAnchor (depth - 1)))
            , Json.Decode.succeed Nothing
            ]


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
            String.foldl (\char total -> total * 31 + Char.toCode char) 0 (Id.toString userId)
                |> modBy (List.length colors)
    in
    List.drop index colors |> List.head |> Maybe.withDefault "#ff5252"


{-| Places the strokes drawn on a message in front of the message view.
-}
wrapMessageView : SeqDict AnchorType ( Float, Float ) -> Maybe (List ( Id UserId, Stroke )) -> Element msg -> Element msg
wrapMessageView anchorOffsets maybeStrokes element =
    case maybeStrokes of
        Just strokes ->
            Ui.el [ Ui.inFront (messageOverlay anchorOffsets strokes) ] element

        Nothing ->
            element


{-| Renders all strokes belonging to a single message. Positioned inFront of
the message container so it moves together with the message when scrolling.
The svg has no size of its own (overflow is visible) and ignores pointer
events so it never blocks interactions with the message below it.
-}
messageOverlay : SeqDict AnchorType ( Float, Float ) -> List ( Id UserId, Stroke ) -> Element msg
messageOverlay anchorOffsets strokes =
    Svg.svg
        [ Svg.Attributes.width "1"
        , Svg.Attributes.height "1"
        , Svg.Attributes.style "position:absolute;left:0;top:0;overflow:visible;pointer-events:none;display:block"
        ]
        (List.filterMap
            (\( userId, stroke ) ->
                case SeqDict.get stroke.anchor anchorOffsets of
                    Just offset ->
                        strokeView (userColor userId) offset stroke |> Just

                    Nothing ->
                        Nothing
            )
            strokes
        )
        |> Ui.html
        |> Ui.el [ Ui.width (Ui.px 0), Ui.height (Ui.px 0), MyUi.htmlStyle "pointer-events" "none" ]


strokeView : String -> ( Float, Float ) -> Stroke -> Svg.Svg msg
strokeView color ( offsetX, offsetY ) stroke =
    Svg.polyline
        [ List.Nonempty.toList stroke.points
            |> List.map
                (\( x, y ) ->
                    String.fromFloat (x + offsetX) ++ "," ++ String.fromFloat (y + offsetY)
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


inputOverlayId : Dom.HtmlId
inputOverlayId =
    Dom.id "drawing_inputOverlay"


{-| Id of the element that listens for anchor picking clicks.
-}
pickAreaId : Dom.HtmlId
pickAreaId =
    Dom.id "drawing_pickArea"


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
            ("[id^='spoiler_drawAnchor']:hover, [id^='spoiler_'][id*='_image_']:hover, [id^='spoiler_'][id*='_file_']:hover {"
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
