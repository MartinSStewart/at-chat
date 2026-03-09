module Evergreen.V146.MessageView exposing (..)

import Effect.Time
import Evergreen.V146.Coord
import Evergreen.V146.CssPixels
import Evergreen.V146.Emoji
import Evergreen.V146.NonemptyDict
import Evergreen.V146.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V146.NonemptyDict.NonemptyDict Int Evergreen.V146.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V146.Coord.Coord Evergreen.V146.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V146.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V146.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V146.Coord.Coord Evergreen.V146.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
