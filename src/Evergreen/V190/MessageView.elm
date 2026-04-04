module Evergreen.V190.MessageView exposing (..)

import Effect.Time
import Evergreen.V190.Coord
import Evergreen.V190.CssPixels
import Evergreen.V190.Emoji
import Evergreen.V190.NonemptyDict
import Evergreen.V190.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V190.NonemptyDict.NonemptyDict Int Evergreen.V190.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V190.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V190.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V190.Coord.Coord Evergreen.V190.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V190.Emoji.Emoji
