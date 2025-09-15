module Evergreen.V60.MessageView exposing (..)

import Effect.Time
import Evergreen.V60.Coord
import Evergreen.V60.CssPixels
import Evergreen.V60.Emoji
import Evergreen.V60.NonemptyDict
import Evergreen.V60.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V60.NonemptyDict.NonemptyDict Int Evergreen.V60.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V60.Coord.Coord Evergreen.V60.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V60.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V60.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V60.Coord.Coord Evergreen.V60.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
