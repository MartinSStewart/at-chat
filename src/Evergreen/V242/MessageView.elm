module Evergreen.V242.MessageView exposing (..)

import Effect.Time
import Evergreen.V242.Coord
import Evergreen.V242.CssPixels
import Evergreen.V242.Emoji
import Evergreen.V242.NonemptyDict
import Evergreen.V242.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V242.NonemptyDict.NonemptyDict Int Evergreen.V242.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V242.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
