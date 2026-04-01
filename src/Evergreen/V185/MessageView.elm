module Evergreen.V185.MessageView exposing (..)

import Effect.Time
import Evergreen.V185.Coord
import Evergreen.V185.CssPixels
import Evergreen.V185.Emoji
import Evergreen.V185.NonemptyDict
import Evergreen.V185.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V185.NonemptyDict.NonemptyDict Int Evergreen.V185.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V185.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V185.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V185.Coord.Coord Evergreen.V185.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V185.Emoji.Emoji
