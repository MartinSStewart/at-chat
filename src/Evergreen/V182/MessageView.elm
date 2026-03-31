module Evergreen.V182.MessageView exposing (..)

import Effect.Time
import Evergreen.V182.Coord
import Evergreen.V182.CssPixels
import Evergreen.V182.Emoji
import Evergreen.V182.NonemptyDict
import Evergreen.V182.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V182.NonemptyDict.NonemptyDict Int Evergreen.V182.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V182.Coord.Coord Evergreen.V182.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V182.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V182.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V182.Coord.Coord Evergreen.V182.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V182.Emoji.Emoji
