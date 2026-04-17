module Evergreen.V203.MessageView exposing (..)

import Effect.Time
import Evergreen.V203.Coord
import Evergreen.V203.CssPixels
import Evergreen.V203.Emoji
import Evergreen.V203.NonemptyDict
import Evergreen.V203.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V203.NonemptyDict.NonemptyDict Int Evergreen.V203.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V203.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V203.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V203.Coord.Coord Evergreen.V203.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V203.Emoji.Emoji
