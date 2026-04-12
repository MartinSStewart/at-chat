module Evergreen.V194.MessageView exposing (..)

import Effect.Time
import Evergreen.V194.Coord
import Evergreen.V194.CssPixels
import Evergreen.V194.Emoji
import Evergreen.V194.NonemptyDict
import Evergreen.V194.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V194.NonemptyDict.NonemptyDict Int Evergreen.V194.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V194.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V194.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V194.Emoji.Emoji
