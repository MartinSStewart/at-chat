module Evergreen.V333.MessageView exposing (..)

import Date
import Duration
import Evergreen.V333.Coord
import Evergreen.V333.CssPixels
import Evergreen.V333.Emoji
import Evergreen.V333.NonemptyDict
import Evergreen.V333.Point2d
import Evergreen.V333.RichText
import Evergreen.V333.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V333.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V333.NonemptyDict.NonemptyDict Int Evergreen.V333.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V333.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V333.Point2d.Point2d Evergreen.V333.CssPixels.CssPixels Evergreen.V333.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V333.Point2d.Point2d Evergreen.V333.CssPixels.CssPixels Evergreen.V333.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V333.Point2d.Point2d Evergreen.V333.CssPixels.CssPixels Evergreen.V333.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V333.Point2d.Point2d Evergreen.V333.CssPixels.CssPixels Evergreen.V333.Touch.ScreenCoordinate) ( Float, Float )
