module Evergreen.V112.MessageView exposing (..)

import Effect.Time
import Evergreen.V112.Coord
import Evergreen.V112.CssPixels
import Evergreen.V112.Emoji
import Evergreen.V112.NonemptyDict
import Evergreen.V112.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V112.NonemptyDict.NonemptyDict Int Evergreen.V112.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V112.Coord.Coord Evergreen.V112.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V112.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V112.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V112.Coord.Coord Evergreen.V112.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
