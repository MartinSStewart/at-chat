module Evergreen.V308.MessageView exposing (..)

import Date
import Duration
import Evergreen.V308.Coord
import Evergreen.V308.CssPixels
import Evergreen.V308.Emoji
import Evergreen.V308.NonemptyDict
import Evergreen.V308.Point2d
import Evergreen.V308.RichText
import Evergreen.V308.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V308.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V308.NonemptyDict.NonemptyDict Int Evergreen.V308.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V308.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V308.Point2d.Point2d Evergreen.V308.CssPixels.CssPixels Evergreen.V308.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V308.Point2d.Point2d Evergreen.V308.CssPixels.CssPixels Evergreen.V308.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V308.Point2d.Point2d Evergreen.V308.CssPixels.CssPixels Evergreen.V308.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V308.Point2d.Point2d Evergreen.V308.CssPixels.CssPixels Evergreen.V308.Touch.ScreenCoordinate) ( Float, Float )
