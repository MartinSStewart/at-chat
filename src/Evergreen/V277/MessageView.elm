module Evergreen.V277.MessageView exposing (..)

import Effect.Time
import Evergreen.V277.Coord
import Evergreen.V277.CssPixels
import Evergreen.V277.Emoji
import Evergreen.V277.NonemptyDict
import Evergreen.V277.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage String (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels)
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Maybe String) (Maybe String) (Evergreen.V277.NonemptyDict.NonemptyDict Int Evergreen.V277.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V277.Coord.Coord Evergreen.V277.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V277.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
