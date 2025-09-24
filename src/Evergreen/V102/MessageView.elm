module Evergreen.V102.MessageView exposing (..)

import Effect.Time
import Evergreen.V102.Coord
import Evergreen.V102.CssPixels
import Evergreen.V102.Emoji
import Evergreen.V102.NonemptyDict
import Evergreen.V102.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V102.NonemptyDict.NonemptyDict Int Evergreen.V102.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V102.Coord.Coord Evergreen.V102.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V102.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V102.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V102.Coord.Coord Evergreen.V102.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
