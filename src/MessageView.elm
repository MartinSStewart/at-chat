module MessageView exposing (MessageViewMsg(..), isPressMsg, miniView)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Emoji exposing (Emoji)
import Html exposing (Html)
import Html.Attributes
import Icons
import Id exposing (ChannelMessageId, Id)
import Json.Decode
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Events


type MessageViewMsg
    = MessageView_PressedSpoiler (Id ChannelMessageId) Int
    | MessageView_MouseEnteredMessage (Id ChannelMessageId)
    | MessageView_MouseExitedMessage (Id ChannelMessageId)
    | MessageView_TouchStart Time.Posix Bool (Id ChannelMessageId) (NonemptyDict Int Touch)
    | MessageView_AltPressedMessage Bool (Id ChannelMessageId) (Coord CssPixels)
    | MessageView_PressedReactionEmoji_Remove (Id ChannelMessageId) Emoji
    | MessageView_PressedReactionEmoji_Add (Id ChannelMessageId) Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink (Id ChannelMessageId)
    | MessageViewMsg_PressedShowReactionEmojiSelector (Id ChannelMessageId) (Coord CssPixels)
    | MessageViewMsg_PressedEditMessage (Id ChannelMessageId)
    | MessageViewMsg_PressedReply (Id ChannelMessageId)
    | MessageViewMsg_PressedShowFullMenu Bool (Id ChannelMessageId) (Coord CssPixels)
    | MessageView_PressedViewThreadLink (Id ChannelMessageId)


isPressMsg : MessageViewMsg -> Bool
isPressMsg msg =
    case msg of
        MessageView_PressedSpoiler _ _ ->
            True

        MessageView_MouseEnteredMessage _ ->
            False

        MessageView_MouseExitedMessage _ ->
            False

        MessageView_TouchStart _ _ _ _ ->
            False

        MessageView_AltPressedMessage _ _ _ ->
            True

        MessageView_PressedReactionEmoji_Remove _ _ ->
            True

        MessageView_PressedReactionEmoji_Add _ _ ->
            True

        MessageView_NoOp ->
            False

        MessageView_PressedReplyLink _ ->
            True

        MessageViewMsg_PressedShowReactionEmojiSelector _ _ ->
            True

        MessageViewMsg_PressedEditMessage _ ->
            True

        MessageViewMsg_PressedReply _ ->
            True

        MessageViewMsg_PressedShowFullMenu _ _ _ ->
            True

        MessageView_PressedViewThreadLink _ ->
            True


miniView : Bool -> Bool -> Id ChannelMessageId -> Element MessageViewMsg
miniView isThreadStarter canEdit messageIndex =
    Ui.row
        [ Ui.alignRight
        , Ui.background MyUi.background1
        , Ui.rounded 4
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.move { x = -48, y = -16, z = 0 }
        , Ui.height (Ui.px 32)
        ]
        [ miniButton
            (Dom.id "miniView_showReactionEmojiSelector")
            (MessageViewMsg_PressedShowReactionEmojiSelector messageIndex)
            Icons.smile
        , if canEdit then
            miniButton
                (Dom.id "miniView_editMessage")
                (\_ -> MessageViewMsg_PressedEditMessage messageIndex)
                Icons.pencil

          else
            Ui.none
        , if isThreadStarter then
            Ui.none

          else
            miniButton
                (Dom.id "miniView_reply")
                (\_ -> MessageViewMsg_PressedReply messageIndex)
                Icons.reply
        , miniButton
            (Dom.id "miniView_showFullMenu")
            (MessageViewMsg_PressedShowFullMenu isThreadStarter messageIndex)
            Icons.dotDotDot
        ]


miniButton : HtmlId -> (Coord CssPixels -> msg) -> Html msg -> Element msg
miniButton htmlId onPress svg =
    Ui.el
        [ Ui.width (Ui.px 32)
        , Ui.paddingXY 4 3
        , Ui.height Ui.fill
        , Ui.htmlAttribute (Html.Attributes.attribute "role" "button")
        , Ui.id (Dom.idToString htmlId)
        , Ui.Events.stopPropagationOn "click"
            (Json.Decode.map2
                (\x y -> ( onPress (Coord.xy (round x) (round y)), True ))
                (Json.Decode.field "clientX" Json.Decode.float)
                (Json.Decode.field "clientY" Json.Decode.float)
            )
        , Ui.pointer
        ]
        (Ui.html svg)
