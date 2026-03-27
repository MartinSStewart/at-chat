module Evergreen.V173.MessageView exposing (..)

import Effect.Time
import Evergreen.V173.Coord
import Evergreen.V173.CssPixels
import Evergreen.V173.Emoji
import Evergreen.V173.NonemptyDict
import Evergreen.V173.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V173.NonemptyDict.NonemptyDict Int Evergreen.V173.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V173.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V173.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V173.Coord.Coord Evergreen.V173.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V173.Emoji.Emoji
