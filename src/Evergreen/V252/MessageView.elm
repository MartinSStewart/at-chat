module Evergreen.V252.MessageView exposing (..)

import Effect.Time
import Evergreen.V252.Coord
import Evergreen.V252.CssPixels
import Evergreen.V252.Emoji
import Evergreen.V252.NonemptyDict
import Evergreen.V252.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V252.NonemptyDict.NonemptyDict Int Evergreen.V252.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V252.Coord.Coord Evergreen.V252.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V252.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
