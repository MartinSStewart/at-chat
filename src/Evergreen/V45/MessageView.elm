module Evergreen.V45.MessageView exposing (..)

import Effect.Time
import Evergreen.V45.Coord
import Evergreen.V45.CssPixels
import Evergreen.V45.Emoji
import Evergreen.V45.NonemptyDict
import Evergreen.V45.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V45.NonemptyDict.NonemptyDict Int Evergreen.V45.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V45.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V45.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels)
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V45.Coord.Coord Evergreen.V45.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
