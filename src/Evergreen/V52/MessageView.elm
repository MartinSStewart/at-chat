module Evergreen.V52.MessageView exposing (..)

import Effect.Time
import Evergreen.V52.Coord
import Evergreen.V52.CssPixels
import Evergreen.V52.Emoji
import Evergreen.V52.NonemptyDict
import Evergreen.V52.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V52.NonemptyDict.NonemptyDict Int Evergreen.V52.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V52.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V52.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V52.Coord.Coord Evergreen.V52.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
