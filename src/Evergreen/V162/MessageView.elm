module Evergreen.V162.MessageView exposing (..)

import Effect.Time
import Evergreen.V162.Coord
import Evergreen.V162.CssPixels
import Evergreen.V162.Emoji
import Evergreen.V162.NonemptyDict
import Evergreen.V162.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V162.NonemptyDict.NonemptyDict Int Evergreen.V162.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V162.Coord.Coord Evergreen.V162.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V162.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V162.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V162.Coord.Coord Evergreen.V162.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
