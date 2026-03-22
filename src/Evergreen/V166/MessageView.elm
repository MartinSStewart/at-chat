module Evergreen.V166.MessageView exposing (..)

import Effect.Time
import Evergreen.V166.Coord
import Evergreen.V166.CssPixels
import Evergreen.V166.Emoji
import Evergreen.V166.NonemptyDict
import Evergreen.V166.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V166.NonemptyDict.NonemptyDict Int Evergreen.V166.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V166.Coord.Coord Evergreen.V166.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V166.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V166.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V166.Coord.Coord Evergreen.V166.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
