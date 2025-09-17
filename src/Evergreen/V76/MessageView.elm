module Evergreen.V76.MessageView exposing (..)

import Effect.Time
import Evergreen.V76.Coord
import Evergreen.V76.CssPixels
import Evergreen.V76.Emoji
import Evergreen.V76.NonemptyDict
import Evergreen.V76.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V76.NonemptyDict.NonemptyDict Int Evergreen.V76.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V76.Coord.Coord Evergreen.V76.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V76.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V76.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V76.Coord.Coord Evergreen.V76.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
