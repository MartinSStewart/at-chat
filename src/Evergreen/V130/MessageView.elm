module Evergreen.V130.MessageView exposing (..)

import Effect.Time
import Evergreen.V130.Coord
import Evergreen.V130.CssPixels
import Evergreen.V130.Emoji
import Evergreen.V130.NonemptyDict
import Evergreen.V130.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V130.NonemptyDict.NonemptyDict Int Evergreen.V130.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V130.Coord.Coord Evergreen.V130.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V130.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V130.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V130.Coord.Coord Evergreen.V130.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
