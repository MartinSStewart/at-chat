module Evergreen.V156.MessageView exposing (..)

import Effect.Time
import Evergreen.V156.Coord
import Evergreen.V156.CssPixels
import Evergreen.V156.Emoji
import Evergreen.V156.NonemptyDict
import Evergreen.V156.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V156.NonemptyDict.NonemptyDict Int Evergreen.V156.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V156.Coord.Coord Evergreen.V156.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V156.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V156.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V156.Coord.Coord Evergreen.V156.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
