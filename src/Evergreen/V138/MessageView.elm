module Evergreen.V138.MessageView exposing (..)

import Effect.Time
import Evergreen.V138.Coord
import Evergreen.V138.CssPixels
import Evergreen.V138.Emoji
import Evergreen.V138.NonemptyDict
import Evergreen.V138.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V138.NonemptyDict.NonemptyDict Int Evergreen.V138.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V138.Coord.Coord Evergreen.V138.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V138.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V138.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V138.Coord.Coord Evergreen.V138.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
