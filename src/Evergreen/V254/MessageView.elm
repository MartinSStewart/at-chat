module Evergreen.V254.MessageView exposing (..)

import Effect.Time
import Evergreen.V254.Coord
import Evergreen.V254.CssPixels
import Evergreen.V254.Emoji
import Evergreen.V254.NonemptyDict
import Evergreen.V254.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V254.NonemptyDict.NonemptyDict Int Evergreen.V254.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V254.Coord.Coord Evergreen.V254.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V254.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V254.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V254.Coord.Coord Evergreen.V254.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V254.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
