module Evergreen.V61.MessageView exposing (..)

import Effect.Time
import Evergreen.V61.Coord
import Evergreen.V61.CssPixels
import Evergreen.V61.Emoji
import Evergreen.V61.NonemptyDict
import Evergreen.V61.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V61.NonemptyDict.NonemptyDict Int Evergreen.V61.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V61.Coord.Coord Evergreen.V61.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V61.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V61.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V61.Coord.Coord Evergreen.V61.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
