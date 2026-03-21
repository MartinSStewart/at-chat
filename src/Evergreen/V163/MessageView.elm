module Evergreen.V163.MessageView exposing (..)

import Effect.Time
import Evergreen.V163.Coord
import Evergreen.V163.CssPixels
import Evergreen.V163.Emoji
import Evergreen.V163.NonemptyDict
import Evergreen.V163.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V163.NonemptyDict.NonemptyDict Int Evergreen.V163.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V163.Coord.Coord Evergreen.V163.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V163.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V163.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V163.Coord.Coord Evergreen.V163.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
