module Evergreen.V93.MessageView exposing (..)

import Effect.Time
import Evergreen.V93.Coord
import Evergreen.V93.CssPixels
import Evergreen.V93.Emoji
import Evergreen.V93.NonemptyDict
import Evergreen.V93.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V93.NonemptyDict.NonemptyDict Int Evergreen.V93.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V93.Coord.Coord Evergreen.V93.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V93.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V93.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V93.Coord.Coord Evergreen.V93.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
