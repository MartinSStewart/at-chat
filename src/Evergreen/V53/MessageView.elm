module Evergreen.V53.MessageView exposing (..)

import Effect.Time
import Evergreen.V53.Coord
import Evergreen.V53.CssPixels
import Evergreen.V53.Emoji
import Evergreen.V53.NonemptyDict
import Evergreen.V53.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V53.NonemptyDict.NonemptyDict Int Evergreen.V53.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V53.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V53.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V53.Coord.Coord Evergreen.V53.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
