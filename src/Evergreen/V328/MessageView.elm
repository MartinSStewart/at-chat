module Evergreen.V328.MessageView exposing (..)

import Date
import Duration
import Evergreen.V328.Coord
import Evergreen.V328.CssPixels
import Evergreen.V328.Emoji
import Evergreen.V328.NonemptyDict
import Evergreen.V328.Point2d
import Evergreen.V328.RichText
import Evergreen.V328.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V328.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V328.NonemptyDict.NonemptyDict Int Evergreen.V328.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V328.Coord.Coord Evergreen.V328.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V328.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V328.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V328.Coord.Coord Evergreen.V328.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V328.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V328.Point2d.Point2d Evergreen.V328.CssPixels.CssPixels Evergreen.V328.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V328.Point2d.Point2d Evergreen.V328.CssPixels.CssPixels Evergreen.V328.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V328.Point2d.Point2d Evergreen.V328.CssPixels.CssPixels Evergreen.V328.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V328.Point2d.Point2d Evergreen.V328.CssPixels.CssPixels Evergreen.V328.Touch.ScreenCoordinate) ( Float, Float )
