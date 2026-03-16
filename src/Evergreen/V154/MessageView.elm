module Evergreen.V154.MessageView exposing (..)

import Effect.Time
import Evergreen.V154.Coord
import Evergreen.V154.CssPixels
import Evergreen.V154.Emoji
import Evergreen.V154.NonemptyDict
import Evergreen.V154.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V154.NonemptyDict.NonemptyDict Int Evergreen.V154.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V154.Coord.Coord Evergreen.V154.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V154.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V154.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V154.Coord.Coord Evergreen.V154.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
