module Evergreen.V144.MessageView exposing (..)

import Effect.Time
import Evergreen.V144.Coord
import Evergreen.V144.CssPixels
import Evergreen.V144.Emoji
import Evergreen.V144.NonemptyDict
import Evergreen.V144.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V144.NonemptyDict.NonemptyDict Int Evergreen.V144.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V144.Coord.Coord Evergreen.V144.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V144.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V144.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V144.Coord.Coord Evergreen.V144.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
