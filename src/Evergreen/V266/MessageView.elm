module Evergreen.V266.MessageView exposing (..)

import Effect.Time
import Evergreen.V266.Coord
import Evergreen.V266.CssPixels
import Evergreen.V266.Emoji
import Evergreen.V266.NonemptyDict
import Evergreen.V266.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V266.NonemptyDict.NonemptyDict Int Evergreen.V266.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V266.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
