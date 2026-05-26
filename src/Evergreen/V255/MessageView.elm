module Evergreen.V255.MessageView exposing (..)

import Effect.Time
import Evergreen.V255.Coord
import Evergreen.V255.CssPixels
import Evergreen.V255.Emoji
import Evergreen.V255.NonemptyDict
import Evergreen.V255.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V255.NonemptyDict.NonemptyDict Int Evergreen.V255.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V255.Coord.Coord Evergreen.V255.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V255.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
