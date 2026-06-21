module Evergreen.V293.MessageView exposing (..)

import Date
import Duration
import Evergreen.V293.Coord
import Evergreen.V293.CssPixels
import Evergreen.V293.Emoji
import Evergreen.V293.NonemptyDict
import Evergreen.V293.Point2d
import Evergreen.V293.RichText
import Evergreen.V293.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V293.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V293.NonemptyDict.NonemptyDict Int Evergreen.V293.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V293.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V293.Point2d.Point2d Evergreen.V293.CssPixels.CssPixels Evergreen.V293.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V293.Point2d.Point2d Evergreen.V293.CssPixels.CssPixels Evergreen.V293.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V293.Point2d.Point2d Evergreen.V293.CssPixels.CssPixels Evergreen.V293.Touch.ScreenCoordinate) ( Float, Float )
