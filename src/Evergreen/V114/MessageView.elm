module Evergreen.V114.MessageView exposing (..)

import Effect.Time
import Evergreen.V114.Coord
import Evergreen.V114.CssPixels
import Evergreen.V114.Emoji
import Evergreen.V114.NonemptyDict
import Evergreen.V114.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V114.NonemptyDict.NonemptyDict Int Evergreen.V114.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V114.Coord.Coord Evergreen.V114.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V114.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V114.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V114.Coord.Coord Evergreen.V114.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
