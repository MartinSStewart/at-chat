module Evergreen.V267.MessageView exposing (..)

import Effect.Time
import Evergreen.V267.Coord
import Evergreen.V267.CssPixels
import Evergreen.V267.Emoji
import Evergreen.V267.NonemptyDict
import Evergreen.V267.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V267.NonemptyDict.NonemptyDict Int Evergreen.V267.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V267.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
