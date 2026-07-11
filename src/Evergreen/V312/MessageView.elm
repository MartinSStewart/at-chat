module Evergreen.V312.MessageView exposing (..)

import Date
import Duration
import Evergreen.V312.Coord
import Evergreen.V312.CssPixels
import Evergreen.V312.Emoji
import Evergreen.V312.NonemptyDict
import Evergreen.V312.Point2d
import Evergreen.V312.RichText
import Evergreen.V312.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V312.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V312.NonemptyDict.NonemptyDict Int Evergreen.V312.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V312.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V312.Point2d.Point2d Evergreen.V312.CssPixels.CssPixels Evergreen.V312.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V312.Point2d.Point2d Evergreen.V312.CssPixels.CssPixels Evergreen.V312.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V312.Point2d.Point2d Evergreen.V312.CssPixels.CssPixels Evergreen.V312.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V312.Point2d.Point2d Evergreen.V312.CssPixels.CssPixels Evergreen.V312.Touch.ScreenCoordinate) ( Float, Float )
