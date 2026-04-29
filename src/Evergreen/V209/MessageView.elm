module Evergreen.V209.MessageView exposing (..)

import Effect.Time
import Evergreen.V209.Coord
import Evergreen.V209.CssPixels
import Evergreen.V209.Emoji
import Evergreen.V209.NonemptyDict
import Evergreen.V209.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V209.NonemptyDict.NonemptyDict Int Evergreen.V209.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V209.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V209.Emoji.Emoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V209.Emoji.Emoji
