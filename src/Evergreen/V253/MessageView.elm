module Evergreen.V253.MessageView exposing (..)

import Effect.Time
import Evergreen.V253.Coord
import Evergreen.V253.CssPixels
import Evergreen.V253.Emoji
import Evergreen.V253.NonemptyDict
import Evergreen.V253.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V253.NonemptyDict.NonemptyDict Int Evergreen.V253.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V253.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
