module Evergreen.V248.MessageView exposing (..)

import Effect.Time
import Evergreen.V248.Coord
import Evergreen.V248.CssPixels
import Evergreen.V248.Emoji
import Evergreen.V248.NonemptyDict
import Evergreen.V248.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V248.NonemptyDict.NonemptyDict Int Evergreen.V248.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V248.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
