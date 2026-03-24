module Evergreen.V169.MessageView exposing (..)

import Effect.Time
import Evergreen.V169.Coord
import Evergreen.V169.CssPixels
import Evergreen.V169.Emoji
import Evergreen.V169.NonemptyDict
import Evergreen.V169.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V169.NonemptyDict.NonemptyDict Int Evergreen.V169.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V169.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V169.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V169.Coord.Coord Evergreen.V169.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
