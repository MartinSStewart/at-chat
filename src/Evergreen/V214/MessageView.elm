module Evergreen.V214.MessageView exposing (..)

import Effect.Time
import Evergreen.V214.Coord
import Evergreen.V214.CssPixels
import Evergreen.V214.Emoji
import Evergreen.V214.NonemptyDict
import Evergreen.V214.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V214.NonemptyDict.NonemptyDict Int Evergreen.V214.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V214.Coord.Coord Evergreen.V214.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V214.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V214.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V214.Coord.Coord Evergreen.V214.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V214.Emoji.EmojiOrCustomEmoji
