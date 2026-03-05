module Evergreen.V134.MessageView exposing (..)

import Effect.Time
import Evergreen.V134.Coord
import Evergreen.V134.CssPixels
import Evergreen.V134.Emoji
import Evergreen.V134.NonemptyDict
import Evergreen.V134.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V134.NonemptyDict.NonemptyDict Int Evergreen.V134.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V134.Coord.Coord Evergreen.V134.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V134.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V134.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V134.Coord.Coord Evergreen.V134.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
