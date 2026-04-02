module Evergreen.V187.MessageView exposing (..)

import Effect.Time
import Evergreen.V187.Coord
import Evergreen.V187.CssPixels
import Evergreen.V187.Emoji
import Evergreen.V187.NonemptyDict
import Evergreen.V187.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V187.NonemptyDict.NonemptyDict Int Evergreen.V187.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V187.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V187.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V187.Coord.Coord Evergreen.V187.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V187.Emoji.Emoji
