module Evergreen.V104.MessageView exposing (..)

import Effect.Time
import Evergreen.V104.Coord
import Evergreen.V104.CssPixels
import Evergreen.V104.Emoji
import Evergreen.V104.NonemptyDict
import Evergreen.V104.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V104.NonemptyDict.NonemptyDict Int Evergreen.V104.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V104.Coord.Coord Evergreen.V104.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V104.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V104.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V104.Coord.Coord Evergreen.V104.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
