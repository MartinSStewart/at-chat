module Evergreen.V261.MessageView exposing (..)

import Effect.Time
import Evergreen.V261.Coord
import Evergreen.V261.CssPixels
import Evergreen.V261.Emoji
import Evergreen.V261.NonemptyDict
import Evergreen.V261.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V261.NonemptyDict.NonemptyDict Int Evergreen.V261.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V261.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
