module Evergreen.V56.MessageView exposing (..)

import Effect.Time
import Evergreen.V56.Coord
import Evergreen.V56.CssPixels
import Evergreen.V56.Emoji
import Evergreen.V56.NonemptyDict
import Evergreen.V56.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V56.NonemptyDict.NonemptyDict Int Evergreen.V56.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V56.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V56.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V56.Coord.Coord Evergreen.V56.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
