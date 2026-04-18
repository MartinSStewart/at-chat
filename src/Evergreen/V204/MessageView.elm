module Evergreen.V204.MessageView exposing (..)

import Effect.Time
import Evergreen.V204.Coord
import Evergreen.V204.CssPixels
import Evergreen.V204.Emoji
import Evergreen.V204.NonemptyDict
import Evergreen.V204.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V204.NonemptyDict.NonemptyDict Int Evergreen.V204.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V204.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V204.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V204.Coord.Coord Evergreen.V204.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V204.Emoji.Emoji
