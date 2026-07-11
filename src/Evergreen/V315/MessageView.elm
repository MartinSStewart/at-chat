module Evergreen.V315.MessageView exposing (..)

import Date
import Duration
import Evergreen.V315.Coord
import Evergreen.V315.CssPixels
import Evergreen.V315.Emoji
import Evergreen.V315.NonemptyDict
import Evergreen.V315.Point2d
import Evergreen.V315.RichText
import Evergreen.V315.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V315.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V315.NonemptyDict.NonemptyDict Int Evergreen.V315.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V315.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V315.Point2d.Point2d Evergreen.V315.CssPixels.CssPixels Evergreen.V315.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V315.Point2d.Point2d Evergreen.V315.CssPixels.CssPixels Evergreen.V315.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V315.Point2d.Point2d Evergreen.V315.CssPixels.CssPixels Evergreen.V315.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V315.Point2d.Point2d Evergreen.V315.CssPixels.CssPixels Evergreen.V315.Touch.ScreenCoordinate) ( Float, Float )
