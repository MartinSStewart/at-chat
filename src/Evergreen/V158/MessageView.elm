module Evergreen.V158.MessageView exposing (..)

import Effect.Time
import Evergreen.V158.Coord
import Evergreen.V158.CssPixels
import Evergreen.V158.Emoji
import Evergreen.V158.NonemptyDict
import Evergreen.V158.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V158.NonemptyDict.NonemptyDict Int Evergreen.V158.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V158.Coord.Coord Evergreen.V158.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V158.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V158.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V158.Coord.Coord Evergreen.V158.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
