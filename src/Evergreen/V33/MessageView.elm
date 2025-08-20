module Evergreen.V33.MessageView exposing (..)

import Effect.Time
import Evergreen.V33.Coord
import Evergreen.V33.CssPixels
import Evergreen.V33.Emoji
import Evergreen.V33.NonemptyDict
import Evergreen.V33.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int Int
    | MessageView_MouseEnteredMessage Int
    | MessageView_MouseExitedMessage Int
    | MessageView_TouchStart Effect.Time.Posix Bool Int (Evergreen.V33.NonemptyDict.NonemptyDict Int Evergreen.V33.Touch.Touch)
    | MessageView_AltPressedMessage Bool Int (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Int Evergreen.V33.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Int Evergreen.V33.Emoji.Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink Int
    | MessageViewMsg_PressedShowReactionEmojiSelector Int (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels)
    | MessageViewMsg_PressedEditMessage Int
    | MessageViewMsg_PressedReply Int
    | MessageViewMsg_PressedShowFullMenu Bool Int (Evergreen.V33.Coord.Coord Evergreen.V33.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink Int
