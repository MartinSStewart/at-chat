module Evergreen.V115.MessageView exposing (..)

import Effect.Time
import Evergreen.V115.Coord
import Evergreen.V115.CssPixels
import Evergreen.V115.Emoji
import Evergreen.V115.NonemptyDict
import Evergreen.V115.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V115.NonemptyDict.NonemptyDict Int Evergreen.V115.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V115.Coord.Coord Evergreen.V115.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V115.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V115.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V115.Coord.Coord Evergreen.V115.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
