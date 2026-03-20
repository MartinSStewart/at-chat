module Evergreen.V160.MessageView exposing (..)

import Effect.Time
import Evergreen.V160.Coord
import Evergreen.V160.CssPixels
import Evergreen.V160.Emoji
import Evergreen.V160.NonemptyDict
import Evergreen.V160.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V160.NonemptyDict.NonemptyDict Int Evergreen.V160.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V160.Coord.Coord Evergreen.V160.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V160.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V160.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V160.Coord.Coord Evergreen.V160.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
