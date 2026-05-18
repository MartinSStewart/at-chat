module Evergreen.V228.MessageView exposing (..)

import Effect.Time
import Evergreen.V228.Coord
import Evergreen.V228.CssPixels
import Evergreen.V228.Emoji
import Evergreen.V228.NonemptyDict
import Evergreen.V228.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V228.NonemptyDict.NonemptyDict Int Evergreen.V228.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V228.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
