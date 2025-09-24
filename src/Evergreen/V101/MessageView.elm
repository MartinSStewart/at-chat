module Evergreen.V101.MessageView exposing (..)

import Effect.Time
import Evergreen.V101.Coord
import Evergreen.V101.CssPixels
import Evergreen.V101.Emoji
import Evergreen.V101.NonemptyDict
import Evergreen.V101.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V101.NonemptyDict.NonemptyDict Int Evergreen.V101.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V101.Coord.Coord Evergreen.V101.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V101.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V101.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V101.Coord.Coord Evergreen.V101.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
