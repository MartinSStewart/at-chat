module Evergreen.V218.MessageView exposing (..)

import Effect.Time
import Evergreen.V218.Coord
import Evergreen.V218.CssPixels
import Evergreen.V218.Emoji
import Evergreen.V218.NonemptyDict
import Evergreen.V218.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V218.NonemptyDict.NonemptyDict Int Evergreen.V218.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V218.Coord.Coord Evergreen.V218.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V218.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
