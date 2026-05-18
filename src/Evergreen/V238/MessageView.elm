module Evergreen.V238.MessageView exposing (..)

import Effect.Time
import Evergreen.V238.Coord
import Evergreen.V238.CssPixels
import Evergreen.V238.Emoji
import Evergreen.V238.NonemptyDict
import Evergreen.V238.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V238.NonemptyDict.NonemptyDict Int Evergreen.V238.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V238.Coord.Coord Evergreen.V238.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V238.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
