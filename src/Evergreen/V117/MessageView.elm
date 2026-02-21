module Evergreen.V117.MessageView exposing (..)

import Effect.Time
import Evergreen.V117.Coord
import Evergreen.V117.CssPixels
import Evergreen.V117.Emoji
import Evergreen.V117.NonemptyDict
import Evergreen.V117.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V117.NonemptyDict.NonemptyDict Int Evergreen.V117.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V117.Coord.Coord Evergreen.V117.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V117.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V117.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V117.Coord.Coord Evergreen.V117.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
