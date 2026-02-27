module Evergreen.V124.MessageView exposing (..)

import Effect.Time
import Evergreen.V124.Coord
import Evergreen.V124.CssPixels
import Evergreen.V124.Emoji
import Evergreen.V124.NonemptyDict
import Evergreen.V124.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V124.NonemptyDict.NonemptyDict Int Evergreen.V124.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V124.Coord.Coord Evergreen.V124.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V124.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V124.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V124.Coord.Coord Evergreen.V124.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
