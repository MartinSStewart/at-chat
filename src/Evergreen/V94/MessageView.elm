module Evergreen.V94.MessageView exposing (..)

import Effect.Time
import Evergreen.V94.Coord
import Evergreen.V94.CssPixels
import Evergreen.V94.Emoji
import Evergreen.V94.NonemptyDict
import Evergreen.V94.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V94.NonemptyDict.NonemptyDict Int Evergreen.V94.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V94.Coord.Coord Evergreen.V94.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V94.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V94.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V94.Coord.Coord Evergreen.V94.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
