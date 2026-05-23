module Evergreen.V250.MessageView exposing (..)

import Effect.Time
import Evergreen.V250.Coord
import Evergreen.V250.CssPixels
import Evergreen.V250.Emoji
import Evergreen.V250.NonemptyDict
import Evergreen.V250.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V250.NonemptyDict.NonemptyDict Int Evergreen.V250.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V250.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
