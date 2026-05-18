module Evergreen.V236.MessageView exposing (..)

import Effect.Time
import Evergreen.V236.Coord
import Evergreen.V236.CssPixels
import Evergreen.V236.Emoji
import Evergreen.V236.NonemptyDict
import Evergreen.V236.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V236.NonemptyDict.NonemptyDict Int Evergreen.V236.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V236.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
