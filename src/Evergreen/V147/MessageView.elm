module Evergreen.V147.MessageView exposing (..)

import Effect.Time
import Evergreen.V147.Coord
import Evergreen.V147.CssPixels
import Evergreen.V147.Emoji
import Evergreen.V147.NonemptyDict
import Evergreen.V147.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V147.NonemptyDict.NonemptyDict Int Evergreen.V147.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V147.Coord.Coord Evergreen.V147.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V147.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V147.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V147.Coord.Coord Evergreen.V147.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
