module Evergreen.V288.MessageView exposing (..)

import Date
import Duration
import Evergreen.V288.Coord
import Evergreen.V288.CssPixels
import Evergreen.V288.Emoji
import Evergreen.V288.NonemptyDict
import Evergreen.V288.Point2d
import Evergreen.V288.RichText
import Evergreen.V288.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V288.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V288.NonemptyDict.NonemptyDict Int Evergreen.V288.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V288.Coord.Coord Evergreen.V288.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V288.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V288.Point2d.Point2d Evergreen.V288.CssPixels.CssPixels Evergreen.V288.Touch.ScreenCoordinate)
    | MessageView_PressedTimestamp (Evergreen.V288.Point2d.Point2d Evergreen.V288.CssPixels.CssPixels Evergreen.V288.Touch.ScreenCoordinate)
    | MessageView_PressedDateDivider Date.Date (Evergreen.V288.Point2d.Point2d Evergreen.V288.CssPixels.CssPixels Evergreen.V288.Touch.ScreenCoordinate)
