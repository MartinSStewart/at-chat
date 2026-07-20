module Evergreen.V332.MessageView exposing (..)

import Date
import Duration
import Evergreen.V332.Coord
import Evergreen.V332.CssPixels
import Evergreen.V332.Emoji
import Evergreen.V332.NonemptyDict
import Evergreen.V332.Point2d
import Evergreen.V332.RichText
import Evergreen.V332.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V332.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V332.NonemptyDict.NonemptyDict Int Evergreen.V332.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V332.Coord.Coord Evergreen.V332.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V332.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V332.Point2d.Point2d Evergreen.V332.CssPixels.CssPixels Evergreen.V332.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V332.Point2d.Point2d Evergreen.V332.CssPixels.CssPixels Evergreen.V332.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V332.Point2d.Point2d Evergreen.V332.CssPixels.CssPixels Evergreen.V332.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V332.Point2d.Point2d Evergreen.V332.CssPixels.CssPixels Evergreen.V332.Touch.ScreenCoordinate) ( Float, Float )
