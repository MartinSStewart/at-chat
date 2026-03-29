module Evergreen.V177.MessageView exposing (..)

import Effect.Time
import Evergreen.V177.Coord
import Evergreen.V177.CssPixels
import Evergreen.V177.Emoji
import Evergreen.V177.NonemptyDict
import Evergreen.V177.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V177.NonemptyDict.NonemptyDict Int Evergreen.V177.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V177.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V177.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V177.Coord.Coord Evergreen.V177.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V177.Emoji.Emoji
