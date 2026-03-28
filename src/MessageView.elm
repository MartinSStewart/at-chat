module MessageView exposing (MessageViewMsg(..), isPressMsg, miniView)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom exposing (HtmlId)
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
import Ui.Anim
import Ui.Events
import Url exposing (Url)
import User exposing (FrontendCurrentUser)


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Time.Posix Bool (NonemptyDict Int Touch)
    | MessageView_AltPressedMessage Bool (Coord CssPixels)
    | MessageView_PressedReactionEmoji_Remove Emoji
    | MessageView_PressedReactionEmoji_Add Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Coord CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Emoji


isPressMsg : MessageViewMsg -> Bool
isPressMsg msg =
    case msg of
        MessageView_PressedSpoiler _ ->
            True

        MessageView_PressedNonWhitelistLink _ ->
            True

        MessageView_MouseEnteredMessage ->
            False

        MessageView_MouseExitedMessage ->
            False

        MessageView_TouchStart _ _ _ ->
            False

        MessageView_AltPressedMessage _ _ ->
            True

        MessageView_PressedReactionEmoji_Remove _ ->
            True

        MessageView_PressedReactionEmoji_Add _ ->
            True

        MessageView_PressedReplyLink ->
            True

        MessageViewMsg_PressedShowReactionEmojiSelector ->
            True

        MessageViewMsg_PressedEditMessage ->
            True

        MessageViewMsg_PressedReply ->
            True

        MessageViewMsg_PressedShowFullMenu _ _ ->
            True

        MessageView_PressedViewThreadLink ->
            True

        MessageView_NoOp ->
            False

        MessageViewMsg_PressedReactionEmoji _ ->
            True


miniView : FrontendCurrentUser -> Bool -> Bool -> Element MessageViewMsg
miniView user isThreadStarter canEdit =
    let
        recentEmojis : List (Element MessageViewMsg)
        recentEmojis =
            User.commonlyUsedEmojis user
                |> List.take 3
                |> List.indexedMap
                    (\index ( emoji, _ ) ->
                        miniButton
                            (Dom.id ("miniView_emojiReact_" ++ String.fromInt index))
                            (MessageViewMsg_PressedReactionEmoji emoji)
                            (Html.div
                                [ Html.Attributes.style "font-size" "20px"
                                , Html.Attributes.style "transform" "translateY(-3px)"
                                ]
                                [ Html.text (Emoji.toString emoji) ]
                            )
                    )
    in
    Ui.row
        [ Ui.alignRight
        , Ui.background MyUi.background1
        , Ui.rounded 4
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.move { x = -48, y = -16, z = 0 }
        , Ui.height (Ui.px 32)
        , Ui.clip
        ]
        (recentEmojis
            ++ [ miniButton
                    (Dom.id "miniView_showReactionEmojiSelector")
                    MessageViewMsg_PressedShowReactionEmojiSelector
                    Icons.smile
               , if canEdit then
                    miniButton
                        (Dom.id "miniView_editMessage")
                        MessageViewMsg_PressedEditMessage
                        Icons.pencil

                 else
                    Ui.none
               , if isThreadStarter then
                    Ui.none

                 else
                    miniButton
                        (Dom.id "miniView_reply")
                        MessageViewMsg_PressedReply
                        Icons.reply
               , miniButtonWithPosition
                    (Dom.id "miniView_showFullMenu")
                    (MessageViewMsg_PressedShowFullMenu isThreadStarter)
                    Icons.dotDotDot
               ]
        )


miniButton : HtmlId -> msg -> Html msg -> Element msg
miniButton htmlId onPress svg =
    Ui.el
        [ Ui.width (Ui.px 32)
        , Ui.paddingXY 4 3
        , Ui.height Ui.fill
        , Ui.id (Dom.idToString htmlId)
        , Ui.Events.stopPropagationOn "click" (Json.Decode.succeed ( onPress, True ))
        , Ui.pointer
        , MyUi.hover False [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        ]
        (Ui.html svg)


miniButtonWithPosition : HtmlId -> (Coord CssPixels -> msg) -> Html msg -> Element msg
miniButtonWithPosition htmlId onPress svg =
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
        , MyUi.hover False [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        ]
        (Ui.html svg)
