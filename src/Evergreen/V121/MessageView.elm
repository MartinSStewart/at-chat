module Evergreen.V121.MessageView exposing (..)

import Effect.Time
import Evergreen.V121.Coord
import Evergreen.V121.CssPixels
import Evergreen.V121.Emoji
import Evergreen.V121.NonemptyDict
import Evergreen.V121.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V121.NonemptyDict.NonemptyDict Int Evergreen.V121.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V121.Coord.Coord Evergreen.V121.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V121.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V121.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V121.Coord.Coord Evergreen.V121.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
