module Evergreen.V161.MessageView exposing (..)

import Effect.Time
import Evergreen.V161.Coord
import Evergreen.V161.CssPixels
import Evergreen.V161.Emoji
import Evergreen.V161.NonemptyDict
import Evergreen.V161.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V161.NonemptyDict.NonemptyDict Int Evergreen.V161.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V161.Coord.Coord Evergreen.V161.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V161.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V161.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V161.Coord.Coord Evergreen.V161.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
