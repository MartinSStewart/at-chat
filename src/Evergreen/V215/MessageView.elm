module Evergreen.V215.MessageView exposing (..)

import Effect.Time
import Evergreen.V215.Coord
import Evergreen.V215.CssPixels
import Evergreen.V215.Emoji
import Evergreen.V215.NonemptyDict
import Evergreen.V215.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V215.NonemptyDict.NonemptyDict Int Evergreen.V215.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V215.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V215.Coord.Coord Evergreen.V215.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V215.Emoji.EmojiOrCustomEmoji
