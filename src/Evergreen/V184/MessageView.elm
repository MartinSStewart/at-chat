module Evergreen.V184.MessageView exposing (..)

import Effect.Time
import Evergreen.V184.Coord
import Evergreen.V184.CssPixels
import Evergreen.V184.Emoji
import Evergreen.V184.NonemptyDict
import Evergreen.V184.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V184.NonemptyDict.NonemptyDict Int Evergreen.V184.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V184.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V184.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V184.Coord.Coord Evergreen.V184.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V184.Emoji.Emoji
