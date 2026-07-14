module Evergreen.V323.MessageView exposing (..)

import Date
import Duration
import Evergreen.V323.Coord
import Evergreen.V323.CssPixels
import Evergreen.V323.Emoji
import Evergreen.V323.NonemptyDict
import Evergreen.V323.Point2d
import Evergreen.V323.RichText
import Evergreen.V323.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V323.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V323.NonemptyDict.NonemptyDict Int Evergreen.V323.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V323.Coord.Coord Evergreen.V323.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V323.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V323.Point2d.Point2d Evergreen.V323.CssPixels.CssPixels Evergreen.V323.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V323.Point2d.Point2d Evergreen.V323.CssPixels.CssPixels Evergreen.V323.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V323.Point2d.Point2d Evergreen.V323.CssPixels.CssPixels Evergreen.V323.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V323.Point2d.Point2d Evergreen.V323.CssPixels.CssPixels Evergreen.V323.Touch.ScreenCoordinate) ( Float, Float )
