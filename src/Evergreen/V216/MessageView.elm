module Evergreen.V216.MessageView exposing (..)

import Effect.Time
import Evergreen.V216.Coord
import Evergreen.V216.CssPixels
import Evergreen.V216.Emoji
import Evergreen.V216.NonemptyDict
import Evergreen.V216.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V216.NonemptyDict.NonemptyDict Int Evergreen.V216.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V216.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
