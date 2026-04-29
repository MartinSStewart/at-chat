module Evergreen.V210.MessageView exposing (..)

import Effect.Time
import Evergreen.V210.Coord
import Evergreen.V210.CssPixels
import Evergreen.V210.Emoji
import Evergreen.V210.NonemptyDict
import Evergreen.V210.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V210.NonemptyDict.NonemptyDict Int Evergreen.V210.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V210.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V210.Coord.Coord Evergreen.V210.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V210.Emoji.EmojiOrCustomEmoji
