module Evergreen.V157.MessageView exposing (..)

import Effect.Time
import Evergreen.V157.Coord
import Evergreen.V157.CssPixels
import Evergreen.V157.Emoji
import Evergreen.V157.NonemptyDict
import Evergreen.V157.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V157.NonemptyDict.NonemptyDict Int Evergreen.V157.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V157.Coord.Coord Evergreen.V157.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V157.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V157.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V157.Coord.Coord Evergreen.V157.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
