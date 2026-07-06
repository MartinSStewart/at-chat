module Evergreen.V304.MessageView exposing (..)

import Date
import Duration
import Evergreen.V304.Coord
import Evergreen.V304.CssPixels
import Evergreen.V304.Emoji
import Evergreen.V304.NonemptyDict
import Evergreen.V304.Point2d
import Evergreen.V304.RichText
import Evergreen.V304.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V304.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V304.NonemptyDict.NonemptyDict Int Evergreen.V304.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V304.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V304.Point2d.Point2d Evergreen.V304.CssPixels.CssPixels Evergreen.V304.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V304.Point2d.Point2d Evergreen.V304.CssPixels.CssPixels Evergreen.V304.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V304.Point2d.Point2d Evergreen.V304.CssPixels.CssPixels Evergreen.V304.Touch.ScreenCoordinate) ( Float, Float )
