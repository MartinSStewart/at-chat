module MessageView exposing (MessageViewMsg(..), isPressMsg, miniView)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Time as Time
import Emoji exposing (Emoji)
import Html exposing (Html)
import Html.Attributes
import Icons
import Json.Decode
import MyUi
import NonemptyDict exposing (NonemptyDict)
import Touch exposing (Touch)
import Ui exposing (Element)
import Ui.Events


type MessageViewMsg
    = MessageView_PressedSpoiler Int Int
    | MessageView_MouseEnteredMessage Int
    | MessageView_MouseExitedMessage Int
    | MessageView_TouchStart Time.Posix Int (NonemptyDict Int Touch)
    | MessageView_AltPressedMessage Int (Coord CssPixels)
    | MessageView_PressedReactionEmoji_Remove Int Emoji
    | MessageView_PressedReactionEmoji_Add Int Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink Int
    | MessageViewMsg_PressedShowReactionEmojiSelector Int (Coord CssPixels)
    | MessageViewMsg_PressedEditMessage Int
    | MessageViewMsg_PressedReply Int
    | MessageViewMsg_PressedShowFullMenu Int (Coord CssPixels)


isPressMsg : MessageViewMsg -> Bool
isPressMsg msg =
    case msg of
        MessageView_PressedSpoiler _ _ ->
            True

        MessageView_MouseEnteredMessage int ->
            False

        MessageView_MouseExitedMessage int ->
            False

        MessageView_TouchStart posix _ nonemptyDict ->
            False

        MessageView_AltPressedMessage int coord ->
            True

        MessageView_PressedReactionEmoji_Remove int emoji ->
            True

        MessageView_PressedReactionEmoji_Add int emoji ->
            True

        MessageView_NoOp ->
            False

        MessageView_PressedReplyLink int ->
            True

        MessageViewMsg_PressedShowReactionEmojiSelector int coord ->
            True

        MessageViewMsg_PressedEditMessage int ->
            True

        MessageViewMsg_PressedReply int ->
            True

        MessageViewMsg_PressedShowFullMenu int coord ->
            True


miniView : Bool -> Int -> Element MessageViewMsg
miniView canEdit messageIndex =
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
        , miniButton (\_ -> MessageViewMsg_PressedReply messageIndex) Icons.reply
        , miniButton (MessageViewMsg_PressedShowFullMenu messageIndex) Icons.dotDotDot
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
