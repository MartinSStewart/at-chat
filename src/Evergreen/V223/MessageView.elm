module Evergreen.V223.MessageView exposing (..)

import Effect.Time
import Evergreen.V223.Coord
import Evergreen.V223.CssPixels
import Evergreen.V223.Emoji
import Evergreen.V223.NonemptyDict
import Evergreen.V223.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V223.NonemptyDict.NonemptyDict Int Evergreen.V223.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V223.Coord.Coord Evergreen.V223.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V223.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V223.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V223.Coord.Coord Evergreen.V223.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V223.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
