module Evergreen.V183.MessageView exposing (..)

import Effect.Time
import Evergreen.V183.Coord
import Evergreen.V183.CssPixels
import Evergreen.V183.Emoji
import Evergreen.V183.NonemptyDict
import Evergreen.V183.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V183.NonemptyDict.NonemptyDict Int Evergreen.V183.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V183.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V183.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V183.Coord.Coord Evergreen.V183.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V183.Emoji.Emoji
