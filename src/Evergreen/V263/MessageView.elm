module Evergreen.V263.MessageView exposing (..)

import Effect.Time
import Evergreen.V263.Coord
import Evergreen.V263.CssPixels
import Evergreen.V263.Emoji
import Evergreen.V263.NonemptyDict
import Evergreen.V263.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V263.NonemptyDict.NonemptyDict Int Evergreen.V263.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V263.Coord.Coord Evergreen.V263.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V263.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
