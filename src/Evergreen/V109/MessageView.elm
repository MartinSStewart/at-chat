module Evergreen.V109.MessageView exposing (..)

import Effect.Time
import Evergreen.V109.Coord
import Evergreen.V109.CssPixels
import Evergreen.V109.Emoji
import Evergreen.V109.NonemptyDict
import Evergreen.V109.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V109.NonemptyDict.NonemptyDict Int Evergreen.V109.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V109.Coord.Coord Evergreen.V109.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V109.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V109.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V109.Coord.Coord Evergreen.V109.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
