module Evergreen.V330.MessageView exposing (..)

import Date
import Duration
import Evergreen.V330.Coord
import Evergreen.V330.CssPixels
import Evergreen.V330.Emoji
import Evergreen.V330.NonemptyDict
import Evergreen.V330.Point2d
import Evergreen.V330.RichText
import Evergreen.V330.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V330.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V330.NonemptyDict.NonemptyDict Int Evergreen.V330.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V330.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V330.Point2d.Point2d Evergreen.V330.CssPixels.CssPixels Evergreen.V330.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V330.Point2d.Point2d Evergreen.V330.CssPixels.CssPixels Evergreen.V330.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V330.Point2d.Point2d Evergreen.V330.CssPixels.CssPixels Evergreen.V330.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V330.Point2d.Point2d Evergreen.V330.CssPixels.CssPixels Evergreen.V330.Touch.ScreenCoordinate) ( Float, Float )
