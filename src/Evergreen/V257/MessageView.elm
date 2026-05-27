module Evergreen.V257.MessageView exposing (..)

import Effect.Time
import Evergreen.V257.Coord
import Evergreen.V257.CssPixels
import Evergreen.V257.Emoji
import Evergreen.V257.NonemptyDict
import Evergreen.V257.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V257.NonemptyDict.NonemptyDict Int Evergreen.V257.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V257.Coord.Coord Evergreen.V257.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V257.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
