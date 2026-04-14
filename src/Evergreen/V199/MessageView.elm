module Evergreen.V199.MessageView exposing (..)

import Effect.Time
import Evergreen.V199.Coord
import Evergreen.V199.CssPixels
import Evergreen.V199.Emoji
import Evergreen.V199.NonemptyDict
import Evergreen.V199.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V199.NonemptyDict.NonemptyDict Int Evergreen.V199.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V199.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V199.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V199.Coord.Coord Evergreen.V199.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V199.Emoji.Emoji
