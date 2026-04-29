module Evergreen.V211.MessageView exposing (..)

import Effect.Time
import Evergreen.V211.Coord
import Evergreen.V211.CssPixels
import Evergreen.V211.Emoji
import Evergreen.V211.NonemptyDict
import Evergreen.V211.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V211.NonemptyDict.NonemptyDict Int Evergreen.V211.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V211.Coord.Coord Evergreen.V211.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V211.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V211.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V211.Coord.Coord Evergreen.V211.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V211.Emoji.EmojiOrCustomEmoji
