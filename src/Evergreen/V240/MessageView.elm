module Evergreen.V240.MessageView exposing (..)

import Effect.Time
import Evergreen.V240.Coord
import Evergreen.V240.CssPixels
import Evergreen.V240.Emoji
import Evergreen.V240.NonemptyDict
import Evergreen.V240.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V240.NonemptyDict.NonemptyDict Int Evergreen.V240.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V240.Coord.Coord Evergreen.V240.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V240.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
