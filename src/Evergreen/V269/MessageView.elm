module Evergreen.V269.MessageView exposing (..)

import Effect.Time
import Evergreen.V269.Coord
import Evergreen.V269.CssPixels
import Evergreen.V269.Emoji
import Evergreen.V269.NonemptyDict
import Evergreen.V269.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage String (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels)
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V269.NonemptyDict.NonemptyDict Int Evergreen.V269.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V269.Coord.Coord Evergreen.V269.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V269.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
