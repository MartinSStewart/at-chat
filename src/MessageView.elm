module MessageView exposing (MessageViewMsg(..), isPressMsg, miniView)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Time as Time
import Emoji exposing (Emoji)
import Html exposing (Html)
import Html.Attributes
import Icons
import Id exposing (Id, MessageId)
import Json.Decode
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Events


type MessageViewMsg
    = MessageView_PressedSpoiler (Id MessageId) Int
    | MessageView_MouseEnteredMessage (Id MessageId)
    | MessageView_MouseExitedMessage (Id MessageId)
    | MessageView_TouchStart Time.Posix Bool (Id MessageId) (NonemptyDict Int Touch)
    | MessageView_AltPressedMessage Bool (Id MessageId) (Coord CssPixels)
    | MessageView_PressedReactionEmoji_Remove (Id MessageId) Emoji
    | MessageView_PressedReactionEmoji_Add (Id MessageId) Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink (Id MessageId)
    | MessageViewMsg_PressedShowReactionEmojiSelector (Id MessageId) (Coord CssPixels)
    | MessageViewMsg_PressedEditMessage (Id MessageId)
    | MessageViewMsg_PressedReply (Id MessageId)
    | MessageViewMsg_PressedShowFullMenu Bool (Id MessageId) (Coord CssPixels)
    | MessageView_PressedViewThreadLink (Id MessageId)


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


miniView : Bool -> Bool -> Id MessageId -> Element MessageViewMsg
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
        [ miniButton (MessageViewMsg_PressedShowReactionEmojiSelector messageIndex) Icons.smile
        , if canEdit then
            miniButton (\_ -> MessageViewMsg_PressedEditMessage messageIndex) Icons.pencil

          else
            Ui.none
        , if isThreadStarter then
            Ui.none

          else
            miniButton (\_ -> MessageViewMsg_PressedReply messageIndex) Icons.reply
        , miniButton (MessageViewMsg_PressedShowFullMenu isThreadStarter messageIndex) Icons.dotDotDot
        ]


miniButton : (Coord CssPixels -> msg) -> Html msg -> Element msg
miniButton onPress svg =
    Ui.el
        [ Ui.width (Ui.px 32)
        , Ui.paddingXY 4 3
        , Ui.height Ui.fill
        , Ui.htmlAttribute (Html.Attributes.attribute "role" "button")

        --, Ui.Input.button onPress
        , Ui.Events.stopPropagationOn "click"
            (Json.Decode.map2
                (\x y -> ( onPress (Coord.xy (round x) (round y)), True ))
                (Json.Decode.field "clientX" Json.Decode.float)
                (Json.Decode.field "clientY" Json.Decode.float)
            )
        , Ui.pointer
        ]
        (Ui.html svg)
