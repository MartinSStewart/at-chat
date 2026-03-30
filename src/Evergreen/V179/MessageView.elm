module Evergreen.V179.MessageView exposing (..)

import Effect.Time
import Evergreen.V179.Coord
import Evergreen.V179.CssPixels
import Evergreen.V179.Emoji
import Evergreen.V179.NonemptyDict
import Evergreen.V179.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V179.NonemptyDict.NonemptyDict Int Evergreen.V179.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V179.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V179.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V179.Coord.Coord Evergreen.V179.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V179.Emoji.Emoji
