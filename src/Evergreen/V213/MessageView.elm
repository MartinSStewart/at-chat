module Evergreen.V213.MessageView exposing (..)

import Effect.Time
import Evergreen.V213.Coord
import Evergreen.V213.CssPixels
import Evergreen.V213.Emoji
import Evergreen.V213.NonemptyDict
import Evergreen.V213.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V213.NonemptyDict.NonemptyDict Int Evergreen.V213.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V213.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V213.Coord.Coord Evergreen.V213.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V213.Emoji.EmojiOrCustomEmoji
