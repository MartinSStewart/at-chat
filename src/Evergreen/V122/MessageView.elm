module Evergreen.V122.MessageView exposing (..)

import Effect.Time
import Evergreen.V122.Coord
import Evergreen.V122.CssPixels
import Evergreen.V122.Emoji
import Evergreen.V122.NonemptyDict
import Evergreen.V122.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V122.NonemptyDict.NonemptyDict Int Evergreen.V122.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V122.Coord.Coord Evergreen.V122.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V122.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V122.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V122.Coord.Coord Evergreen.V122.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
