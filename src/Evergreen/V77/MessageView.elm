module Evergreen.V77.MessageView exposing (..)

import Effect.Time
import Evergreen.V77.Coord
import Evergreen.V77.CssPixels
import Evergreen.V77.Emoji
import Evergreen.V77.NonemptyDict
import Evergreen.V77.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V77.NonemptyDict.NonemptyDict Int Evergreen.V77.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V77.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V77.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V77.Coord.Coord Evergreen.V77.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
