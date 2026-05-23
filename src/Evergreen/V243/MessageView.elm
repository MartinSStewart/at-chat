module Evergreen.V243.MessageView exposing (..)

import Effect.Time
import Evergreen.V243.Coord
import Evergreen.V243.CssPixels
import Evergreen.V243.Emoji
import Evergreen.V243.NonemptyDict
import Evergreen.V243.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V243.NonemptyDict.NonemptyDict Int Evergreen.V243.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V243.Coord.Coord Evergreen.V243.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V243.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
