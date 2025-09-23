module Evergreen.V97.MessageView exposing (..)

import Effect.Time
import Evergreen.V97.Coord
import Evergreen.V97.CssPixels
import Evergreen.V97.Emoji
import Evergreen.V97.NonemptyDict
import Evergreen.V97.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V97.NonemptyDict.NonemptyDict Int Evergreen.V97.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V97.Coord.Coord Evergreen.V97.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V97.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V97.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V97.Coord.Coord Evergreen.V97.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
