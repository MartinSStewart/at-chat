module Evergreen.V251.MessageView exposing (..)

import Effect.Time
import Evergreen.V251.Coord
import Evergreen.V251.CssPixels
import Evergreen.V251.Emoji
import Evergreen.V251.NonemptyDict
import Evergreen.V251.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V251.NonemptyDict.NonemptyDict Int Evergreen.V251.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V251.Coord.Coord Evergreen.V251.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V251.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
