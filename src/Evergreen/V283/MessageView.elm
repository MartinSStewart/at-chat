module Evergreen.V283.MessageView exposing (..)

import Effect.Time
import Evergreen.V283.Coord
import Evergreen.V283.CssPixels
import Evergreen.V283.Emoji
import Evergreen.V283.NonemptyDict
import Evergreen.V283.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage String (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels)
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Maybe String) (Maybe String) (Evergreen.V283.NonemptyDict.NonemptyDict Int Evergreen.V283.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V283.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
