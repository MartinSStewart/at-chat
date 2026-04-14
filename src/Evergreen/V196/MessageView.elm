module Evergreen.V196.MessageView exposing (..)

import Effect.Time
import Evergreen.V196.Coord
import Evergreen.V196.CssPixels
import Evergreen.V196.Emoji
import Evergreen.V196.NonemptyDict
import Evergreen.V196.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V196.NonemptyDict.NonemptyDict Int Evergreen.V196.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V196.Coord.Coord Evergreen.V196.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V196.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V196.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V196.Coord.Coord Evergreen.V196.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V196.Emoji.Emoji
