module Evergreen.V176.MessageView exposing (..)

import Effect.Time
import Evergreen.V176.Coord
import Evergreen.V176.CssPixels
import Evergreen.V176.Emoji
import Evergreen.V176.NonemptyDict
import Evergreen.V176.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V176.NonemptyDict.NonemptyDict Int Evergreen.V176.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V176.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V176.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V176.Coord.Coord Evergreen.V176.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V176.Emoji.Emoji
