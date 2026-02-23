module Evergreen.V118.MessageView exposing (..)

import Effect.Time
import Evergreen.V118.Coord
import Evergreen.V118.CssPixels
import Evergreen.V118.Emoji
import Evergreen.V118.NonemptyDict
import Evergreen.V118.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V118.NonemptyDict.NonemptyDict Int Evergreen.V118.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V118.Coord.Coord Evergreen.V118.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V118.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V118.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V118.Coord.Coord Evergreen.V118.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
