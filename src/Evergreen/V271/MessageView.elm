module Evergreen.V271.MessageView exposing (..)

import Effect.Time
import Evergreen.V271.Coord
import Evergreen.V271.CssPixels
import Evergreen.V271.Emoji
import Evergreen.V271.NonemptyDict
import Evergreen.V271.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage String (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels)
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Maybe String) (Maybe String) (Evergreen.V271.NonemptyDict.NonemptyDict Int Evergreen.V271.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V271.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
