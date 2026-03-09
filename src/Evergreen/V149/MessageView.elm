module Evergreen.V149.MessageView exposing (..)

import Effect.Time
import Evergreen.V149.Coord
import Evergreen.V149.CssPixels
import Evergreen.V149.Emoji
import Evergreen.V149.NonemptyDict
import Evergreen.V149.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V149.NonemptyDict.NonemptyDict Int Evergreen.V149.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V149.Coord.Coord Evergreen.V149.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V149.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V149.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V149.Coord.Coord Evergreen.V149.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
