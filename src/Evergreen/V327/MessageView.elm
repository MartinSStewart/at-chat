module Evergreen.V327.MessageView exposing (..)

import Date
import Duration
import Evergreen.V327.Coord
import Evergreen.V327.CssPixels
import Evergreen.V327.Emoji
import Evergreen.V327.NonemptyDict
import Evergreen.V327.Point2d
import Evergreen.V327.RichText
import Evergreen.V327.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V327.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V327.NonemptyDict.NonemptyDict Int Evergreen.V327.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V327.Coord.Coord Evergreen.V327.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V327.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V327.Point2d.Point2d Evergreen.V327.CssPixels.CssPixels Evergreen.V327.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V327.Point2d.Point2d Evergreen.V327.CssPixels.CssPixels Evergreen.V327.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V327.Point2d.Point2d Evergreen.V327.CssPixels.CssPixels Evergreen.V327.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V327.Point2d.Point2d Evergreen.V327.CssPixels.CssPixels Evergreen.V327.Touch.ScreenCoordinate) ( Float, Float )
