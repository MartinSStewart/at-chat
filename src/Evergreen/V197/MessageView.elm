module Evergreen.V197.MessageView exposing (..)

import Effect.Time
import Evergreen.V197.Coord
import Evergreen.V197.CssPixels
import Evergreen.V197.Emoji
import Evergreen.V197.NonemptyDict
import Evergreen.V197.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V197.NonemptyDict.NonemptyDict Int Evergreen.V197.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V197.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V197.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V197.Emoji.Emoji
