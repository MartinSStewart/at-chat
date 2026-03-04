module Evergreen.V128.MessageView exposing (..)

import Effect.Time
import Evergreen.V128.Coord
import Evergreen.V128.CssPixels
import Evergreen.V128.Emoji
import Evergreen.V128.NonemptyDict
import Evergreen.V128.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V128.NonemptyDict.NonemptyDict Int Evergreen.V128.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V128.Coord.Coord Evergreen.V128.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V128.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V128.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V128.Coord.Coord Evergreen.V128.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
