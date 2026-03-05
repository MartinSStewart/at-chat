module Evergreen.V135.MessageView exposing (..)

import Effect.Time
import Evergreen.V135.Coord
import Evergreen.V135.CssPixels
import Evergreen.V135.Emoji
import Evergreen.V135.NonemptyDict
import Evergreen.V135.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V135.NonemptyDict.NonemptyDict Int Evergreen.V135.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V135.Coord.Coord Evergreen.V135.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V135.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V135.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V135.Coord.Coord Evergreen.V135.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
