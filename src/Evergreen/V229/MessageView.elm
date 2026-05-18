module Evergreen.V229.MessageView exposing (..)

import Effect.Time
import Evergreen.V229.Coord
import Evergreen.V229.CssPixels
import Evergreen.V229.Emoji
import Evergreen.V229.NonemptyDict
import Evergreen.V229.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V229.NonemptyDict.NonemptyDict Int Evergreen.V229.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V229.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
