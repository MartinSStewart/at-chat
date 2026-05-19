module Evergreen.V239.MessageView exposing (..)

import Effect.Time
import Evergreen.V239.Coord
import Evergreen.V239.CssPixels
import Evergreen.V239.Emoji
import Evergreen.V239.NonemptyDict
import Evergreen.V239.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V239.NonemptyDict.NonemptyDict Int Evergreen.V239.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V239.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
