module Evergreen.V275.MessageView exposing (..)

import Effect.Time
import Evergreen.V275.Coord
import Evergreen.V275.CssPixels
import Evergreen.V275.Emoji
import Evergreen.V275.NonemptyDict
import Evergreen.V275.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage String (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels)
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Maybe String) (Maybe String) (Evergreen.V275.NonemptyDict.NonemptyDict Int Evergreen.V275.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V275.Coord.Coord Evergreen.V275.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V275.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
