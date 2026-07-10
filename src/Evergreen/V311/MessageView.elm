module Evergreen.V311.MessageView exposing (..)

import Date
import Duration
import Evergreen.V311.Coord
import Evergreen.V311.CssPixels
import Evergreen.V311.Emoji
import Evergreen.V311.NonemptyDict
import Evergreen.V311.Point2d
import Evergreen.V311.RichText
import Evergreen.V311.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V311.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V311.NonemptyDict.NonemptyDict Int Evergreen.V311.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V311.Coord.Coord Evergreen.V311.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V311.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V311.Point2d.Point2d Evergreen.V311.CssPixels.CssPixels Evergreen.V311.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V311.Point2d.Point2d Evergreen.V311.CssPixels.CssPixels Evergreen.V311.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V311.Point2d.Point2d Evergreen.V311.CssPixels.CssPixels Evergreen.V311.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V311.Point2d.Point2d Evergreen.V311.CssPixels.CssPixels Evergreen.V311.Touch.ScreenCoordinate) ( Float, Float )
