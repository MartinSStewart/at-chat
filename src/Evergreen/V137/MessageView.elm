module Evergreen.V137.MessageView exposing (..)

import Effect.Time
import Evergreen.V137.Coord
import Evergreen.V137.CssPixels
import Evergreen.V137.Emoji
import Evergreen.V137.NonemptyDict
import Evergreen.V137.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V137.NonemptyDict.NonemptyDict Int Evergreen.V137.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V137.Coord.Coord Evergreen.V137.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V137.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V137.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V137.Coord.Coord Evergreen.V137.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
