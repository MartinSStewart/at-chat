module Evergreen.V175.MessageView exposing (..)

import Effect.Time
import Evergreen.V175.Coord
import Evergreen.V175.CssPixels
import Evergreen.V175.Emoji
import Evergreen.V175.NonemptyDict
import Evergreen.V175.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V175.NonemptyDict.NonemptyDict Int Evergreen.V175.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V175.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V175.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V175.Coord.Coord Evergreen.V175.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V175.Emoji.Emoji
