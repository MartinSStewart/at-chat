module Evergreen.V316.MessageView exposing (..)

import Date
import Duration
import Evergreen.V316.Coord
import Evergreen.V316.CssPixels
import Evergreen.V316.Emoji
import Evergreen.V316.NonemptyDict
import Evergreen.V316.Point2d
import Evergreen.V316.RichText
import Evergreen.V316.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V316.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V316.NonemptyDict.NonemptyDict Int Evergreen.V316.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V316.Coord.Coord Evergreen.V316.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V316.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V316.Point2d.Point2d Evergreen.V316.CssPixels.CssPixels Evergreen.V316.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V316.Point2d.Point2d Evergreen.V316.CssPixels.CssPixels Evergreen.V316.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V316.Point2d.Point2d Evergreen.V316.CssPixels.CssPixels Evergreen.V316.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V316.Point2d.Point2d Evergreen.V316.CssPixels.CssPixels Evergreen.V316.Touch.ScreenCoordinate) ( Float, Float )
