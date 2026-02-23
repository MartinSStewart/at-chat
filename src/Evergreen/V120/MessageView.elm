module Evergreen.V120.MessageView exposing (..)

import Effect.Time
import Evergreen.V120.Coord
import Evergreen.V120.CssPixels
import Evergreen.V120.Emoji
import Evergreen.V120.NonemptyDict
import Evergreen.V120.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V120.NonemptyDict.NonemptyDict Int Evergreen.V120.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V120.Coord.Coord Evergreen.V120.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V120.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V120.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V120.Coord.Coord Evergreen.V120.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
