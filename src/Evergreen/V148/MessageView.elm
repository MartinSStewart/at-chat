module Evergreen.V148.MessageView exposing (..)

import Effect.Time
import Evergreen.V148.Coord
import Evergreen.V148.CssPixels
import Evergreen.V148.Emoji
import Evergreen.V148.NonemptyDict
import Evergreen.V148.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V148.NonemptyDict.NonemptyDict Int Evergreen.V148.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V148.Coord.Coord Evergreen.V148.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V148.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V148.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V148.Coord.Coord Evergreen.V148.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
