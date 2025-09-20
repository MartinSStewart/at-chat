module Evergreen.V92.MessageView exposing (..)

import Effect.Time
import Evergreen.V92.Coord
import Evergreen.V92.CssPixels
import Evergreen.V92.Emoji
import Evergreen.V92.NonemptyDict
import Evergreen.V92.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V92.NonemptyDict.NonemptyDict Int Evergreen.V92.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V92.Coord.Coord Evergreen.V92.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V92.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V92.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V92.Coord.Coord Evergreen.V92.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
