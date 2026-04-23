module Evergreen.V207.MessageView exposing (..)

import Effect.Time
import Evergreen.V207.Coord
import Evergreen.V207.CssPixels
import Evergreen.V207.Emoji
import Evergreen.V207.NonemptyDict
import Evergreen.V207.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V207.NonemptyDict.NonemptyDict Int Evergreen.V207.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V207.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V207.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V207.Emoji.Emoji
