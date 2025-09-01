module Evergreen.V46.MessageView exposing (..)

import Effect.Time
import Evergreen.V46.Coord
import Evergreen.V46.CssPixels
import Evergreen.V46.Emoji
import Evergreen.V46.NonemptyDict
import Evergreen.V46.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V46.NonemptyDict.NonemptyDict Int Evergreen.V46.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V46.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V46.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels)
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V46.Coord.Coord Evergreen.V46.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
