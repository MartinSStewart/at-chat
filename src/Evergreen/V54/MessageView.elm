module Evergreen.V54.MessageView exposing (..)

import Effect.Time
import Evergreen.V54.Coord
import Evergreen.V54.CssPixels
import Evergreen.V54.Emoji
import Evergreen.V54.NonemptyDict
import Evergreen.V54.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V54.NonemptyDict.NonemptyDict Int Evergreen.V54.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V54.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V54.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V54.Coord.Coord Evergreen.V54.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
