module Evergreen.V49.MessageView exposing (..)

import Effect.Time
import Evergreen.V49.Coord
import Evergreen.V49.CssPixels
import Evergreen.V49.Emoji
import Evergreen.V49.NonemptyDict
import Evergreen.V49.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V49.NonemptyDict.NonemptyDict Int Evergreen.V49.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V49.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V49.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V49.Coord.Coord Evergreen.V49.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
