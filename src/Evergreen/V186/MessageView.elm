module Evergreen.V186.MessageView exposing (..)

import Effect.Time
import Evergreen.V186.Coord
import Evergreen.V186.CssPixels
import Evergreen.V186.Emoji
import Evergreen.V186.NonemptyDict
import Evergreen.V186.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V186.NonemptyDict.NonemptyDict Int Evergreen.V186.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V186.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V186.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V186.Coord.Coord Evergreen.V186.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V186.Emoji.Emoji
