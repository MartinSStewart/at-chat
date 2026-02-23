module Evergreen.V119.MessageView exposing (..)

import Effect.Time
import Evergreen.V119.Coord
import Evergreen.V119.CssPixels
import Evergreen.V119.Emoji
import Evergreen.V119.NonemptyDict
import Evergreen.V119.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V119.NonemptyDict.NonemptyDict Int Evergreen.V119.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V119.Coord.Coord Evergreen.V119.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V119.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V119.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V119.Coord.Coord Evergreen.V119.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
