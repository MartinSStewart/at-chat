module Evergreen.V217.MessageView exposing (..)

import Effect.Time
import Evergreen.V217.Coord
import Evergreen.V217.CssPixels
import Evergreen.V217.Emoji
import Evergreen.V217.NonemptyDict
import Evergreen.V217.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V217.NonemptyDict.NonemptyDict Int Evergreen.V217.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V217.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
