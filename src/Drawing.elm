module Drawing exposing
    ( ActiveStroke
    , Anchor
    , AnchorType(..)
    , ChannelDrawing
    , LocalChange(..)
    , Model
    , Msg(..)
    , SelectedAnchor
    , Stroke
    , TargetChannel(..)
    , anchorDomId
    , anchorDomIdFallback
    , anchorFromDomId
    , applyChange
    , channelAnchors
    , init
    , initialAnchorSelection
    , inputOverlay
    , instructionsBanner
    , messageOverlay
    , pickAnchorDecoder
    , profileImageAnchorId
    , strokesByMessage
    , targetChannel
    , timestampAnchorId
    , userColor
    , wrapMessageView
    )

import Discord
import Effect.Browser.Dom as Dom
import FileStatus exposing (FileId)
import Html
import Html.Attributes
import Html.Events
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, UserId)
import Json.Decode
import List.Nonempty exposing (Nonempty(..))
import MyUi
import SeqDict exposing (SeqDict)
import Svg
import Svg.Attributes
import Ui exposing (Element)
import Ui.Font


{-| Identifies which channel a drawing belongs to. Unlike AnyGuildOrDmId this
doesn't include the viewer's Discord user id, so every user ends up with the
same key for the same channel.
-}
type TargetChannel
    = TargetGuildChannel (Id GuildId) (Id ChannelId)
    | TargetDmChannel (Id UserId)
    | TargetDiscordGuildChannel (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId)
    | TargetDiscordDmChannel (Discord.Id Discord.PrivateChannelId)


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
    { anchor : Anchor
    , points : Nonempty ( Float, Float )
    }


type alias ChannelDrawing =
    { finished : List { createdBy : Id UserId, stroke : Stroke }
    , inProgress : SeqDict (Id UserId) Stroke
    }


type LocalChange
    = StartStroke Anchor ( Float, Float )
    | ContinueStroke (Nonempty ( Float, Float ))
    | EndStroke


type Msg
    = PickedAnchor (Maybe Anchor)
    | GotAnchorElement Anchor (Result Dom.Error { anchor : Dom.Element, container : Dom.Element })
    | MouseDown Float Float
    | MouseMoved Float Float
    | MouseUp


{-| State of the drawing tool for the current user (only exists while the
drawing mode is enabled).
-}
type alias Model =
    { channel : AnyGuildOrDmId
    , anchor : Maybe SelectedAnchor
    }


type alias SelectedAnchor =
    { anchor : Anchor
    , -- Position of the anchor element in viewport coordinates, used to convert
      -- mouse positions into anchor relative points. Nothing while being measured.
      position : Maybe ( Float, Float )
    , stroke : Maybe ActiveStroke
    }


type alias ActiveStroke =
    { -- Anchor relative points that haven't been sent to the backend yet, newest first
      unsent : List ( Float, Float )
    }


init : AnyGuildOrDmId -> Model
init channel =
    { channel = channel, anchor = Nothing }


initialAnchorSelection : Anchor -> SelectedAnchor
initialAnchorSelection anchor =
    { anchor = anchor, position = Nothing, stroke = Nothing }


targetChannel : AnyGuildOrDmId -> TargetChannel
targetChannel guildOrDmId =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            TargetGuildChannel guildId channelId

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            TargetDmChannel otherUserId

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ guildId channelId) ->
            TargetDiscordGuildChannel guildId channelId

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            TargetDiscordDmChannel data.channelId


maxFinishedStrokes : Int
maxFinishedStrokes =
    200


maxPointsPerStroke : Int
maxPointsPerStroke =
    4000


applyChange :
    Id UserId
    -> AnyGuildOrDmId
    -> LocalChange
    -> SeqDict TargetChannel ChannelDrawing
    -> SeqDict TargetChannel ChannelDrawing
applyChange userId guildOrDmId change drawings =
    let
        key : TargetChannel
        key =
            targetChannel guildOrDmId

        drawing : ChannelDrawing
        drawing =
            SeqDict.get key drawings
                |> Maybe.withDefault { finished = [], inProgress = SeqDict.empty }
    in
    case change of
        StartStroke anchor point ->
            SeqDict.insert
                key
                { drawing
                    | inProgress =
                        SeqDict.insert
                            userId
                            { anchor = anchor, points = Nonempty point [] }
                            drawing.inProgress
                }
                drawings

        ContinueStroke points ->
            case SeqDict.get userId drawing.inProgress of
                Just stroke ->
                    SeqDict.insert
                        key
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
                        drawings

                Nothing ->
                    drawings

        EndStroke ->
            case SeqDict.get userId drawing.inProgress of
                Just stroke ->
                    SeqDict.insert
                        key
                        { drawing
                            | inProgress = SeqDict.remove userId drawing.inProgress
                            , finished =
                                { createdBy = userId, stroke = stroke }
                                    :: drawing.finished
                                    |> List.take maxFinishedStrokes
                        }
                        drawings

                Nothing ->
                    drawings


nonemptyTake : Int -> Nonempty a -> Nonempty a
nonemptyTake amount (Nonempty head rest) =
    Nonempty head (List.take (amount - 1) rest)


{-| All anchors that have at least one stroke attached to them.
-}
channelAnchors : ChannelDrawing -> List Anchor
channelAnchors drawing =
    List.map (\finished -> finished.stroke.anchor) drawing.finished
        ++ List.map .anchor (SeqDict.values drawing.inProgress)
        |> List.foldl
            (\anchor list ->
                if List.member anchor list then
                    list

                else
                    anchor :: list
            )
            []


strokesByMessage : ChannelDrawing -> SeqDict (Id ChannelMessageId) (List ( Id UserId, Stroke ))
strokesByMessage drawing =
    List.map (\finished -> ( finished.createdBy, finished.stroke )) drawing.finished
        ++ SeqDict.toList drawing.inProgress
        |> List.foldl
            (\( userId, stroke ) dict ->
                SeqDict.update
                    stroke.anchor.messageId
                    (\maybe -> ( userId, stroke ) :: Maybe.withDefault [] maybe |> Just)
                    dict
            )
            SeqDict.empty



-- DOM ids used for locating anchor elements. The "spoiler" prefix matches the
-- htmlIdPrefix used for channel messages (attached images already get an id of
-- the form "spoiler_<messageIndex>_image_<fileId>" from RichText.view).


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
pickAnchorDecoder : Json.Decode.Decoder (Maybe Anchor)
pickAnchorDecoder =
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
wrapMessageView : SeqDict Anchor ( Float, Float ) -> Maybe (List ( Id UserId, Stroke )) -> Element msg -> Element msg
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
messageOverlay : SeqDict Anchor ( Float, Float ) -> List ( Id UserId, Stroke ) -> Element msg
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


{-| Transparent overlay that captures mouse events while the user is drawing.
-}
inputOverlay : Bool -> (Msg -> msg) -> Element msg
inputOverlay strokeActive toMsg =
    Html.div
        ([ Html.Attributes.style "position" "absolute"
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
                            mousePositionDecoder MouseDown

                        else
                            Json.Decode.fail "Only drawing with the primary mouse button is supported"
                    )
            )
         ]
            ++ (if strokeActive then
                    [ Html.Events.on "mousemove" (mousePositionDecoder MouseMoved)
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
        |> Ui.el [ Ui.width Ui.fill, Ui.height Ui.fill ]


mousePositionDecoder : (Float -> Float -> Msg) -> Json.Decode.Decoder Msg
mousePositionDecoder toMsg =
    Json.Decode.map2
        toMsg
        (Json.Decode.field "clientX" Json.Decode.float)
        (Json.Decode.field "clientY" Json.Decode.float)


instructionsBanner : String -> Element msg
instructionsBanner text =
    Ui.el
        [ Ui.centerX
        , Ui.alignTop
        , Ui.width Ui.shrink
        , Ui.move { x = 0, y = 8, z = 0 }
        , Ui.paddingXY 12 6
        , Ui.rounded 8
        , Ui.background (Ui.rgba 0 0 0 0.7)
        , Ui.Font.color (Ui.rgb 255 255 255)
        , Ui.Font.size 14
        , MyUi.htmlStyle "pointer-events" "none"
        ]
        (Ui.text text)
