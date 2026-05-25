module Evergreen.V247.MessageView exposing (..)

import Effect.Time
import Evergreen.V247.Coord
import Evergreen.V247.CssPixels
import Evergreen.V247.Emoji
import Evergreen.V247.NonemptyDict
import Evergreen.V247.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V247.NonemptyDict.NonemptyDict Int Evergreen.V247.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V247.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
