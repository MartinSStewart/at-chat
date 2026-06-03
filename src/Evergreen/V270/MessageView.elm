module Evergreen.V270.MessageView exposing (..)

import Effect.Time
import Evergreen.V270.Coord
import Evergreen.V270.CssPixels
import Evergreen.V270.Emoji
import Evergreen.V270.NonemptyDict
import Evergreen.V270.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage String (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels)
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Maybe String) (Maybe String) (Evergreen.V270.NonemptyDict.NonemptyDict Int Evergreen.V270.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V270.Coord.Coord Evergreen.V270.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V270.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
