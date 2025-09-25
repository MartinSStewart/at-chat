module Evergreen.V108.MessageView exposing (..)

import Effect.Time
import Evergreen.V108.Coord
import Evergreen.V108.CssPixels
import Evergreen.V108.Emoji
import Evergreen.V108.NonemptyDict
import Evergreen.V108.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V108.NonemptyDict.NonemptyDict Int Evergreen.V108.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V108.Coord.Coord Evergreen.V108.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V108.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V108.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V108.Coord.Coord Evergreen.V108.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
