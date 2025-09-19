module Evergreen.V90.MessageView exposing (..)

import Effect.Time
import Evergreen.V90.Coord
import Evergreen.V90.CssPixels
import Evergreen.V90.Emoji
import Evergreen.V90.NonemptyDict
import Evergreen.V90.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V90.NonemptyDict.NonemptyDict Int Evergreen.V90.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V90.Coord.Coord Evergreen.V90.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V90.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V90.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V90.Coord.Coord Evergreen.V90.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
