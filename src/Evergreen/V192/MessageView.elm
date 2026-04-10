module Evergreen.V192.MessageView exposing (..)

import Effect.Time
import Evergreen.V192.Coord
import Evergreen.V192.CssPixels
import Evergreen.V192.Emoji
import Evergreen.V192.NonemptyDict
import Evergreen.V192.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V192.NonemptyDict.NonemptyDict Int Evergreen.V192.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V192.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V192.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V192.Coord.Coord Evergreen.V192.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V192.Emoji.Emoji
