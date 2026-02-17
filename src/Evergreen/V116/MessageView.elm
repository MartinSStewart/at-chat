module Evergreen.V116.MessageView exposing (..)

import Effect.Time
import Evergreen.V116.Coord
import Evergreen.V116.CssPixels
import Evergreen.V116.Emoji
import Evergreen.V116.NonemptyDict
import Evergreen.V116.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V116.NonemptyDict.NonemptyDict Int Evergreen.V116.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V116.Coord.Coord Evergreen.V116.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V116.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V116.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V116.Coord.Coord Evergreen.V116.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
