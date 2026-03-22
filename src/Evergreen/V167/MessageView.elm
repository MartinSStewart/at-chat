module Evergreen.V167.MessageView exposing (..)

import Effect.Time
import Evergreen.V167.Coord
import Evergreen.V167.CssPixels
import Evergreen.V167.Emoji
import Evergreen.V167.NonemptyDict
import Evergreen.V167.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V167.NonemptyDict.NonemptyDict Int Evergreen.V167.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V167.Coord.Coord Evergreen.V167.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V167.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V167.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V167.Coord.Coord Evergreen.V167.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
