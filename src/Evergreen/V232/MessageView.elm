module Evergreen.V232.MessageView exposing (..)

import Effect.Time
import Evergreen.V232.Coord
import Evergreen.V232.CssPixels
import Evergreen.V232.Emoji
import Evergreen.V232.NonemptyDict
import Evergreen.V232.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V232.NonemptyDict.NonemptyDict Int Evergreen.V232.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V232.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
