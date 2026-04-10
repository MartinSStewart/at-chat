module Evergreen.V193.MessageView exposing (..)

import Effect.Time
import Evergreen.V193.Coord
import Evergreen.V193.CssPixels
import Evergreen.V193.Emoji
import Evergreen.V193.NonemptyDict
import Evergreen.V193.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V193.NonemptyDict.NonemptyDict Int Evergreen.V193.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V193.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V193.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V193.Emoji.Emoji
