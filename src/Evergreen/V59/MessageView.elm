module Evergreen.V59.MessageView exposing (..)

import Effect.Time
import Evergreen.V59.Coord
import Evergreen.V59.CssPixels
import Evergreen.V59.Emoji
import Evergreen.V59.NonemptyDict
import Evergreen.V59.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V59.NonemptyDict.NonemptyDict Int Evergreen.V59.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V59.Coord.Coord Evergreen.V59.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V59.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V59.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V59.Coord.Coord Evergreen.V59.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
