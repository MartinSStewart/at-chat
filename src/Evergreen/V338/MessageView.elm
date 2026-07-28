module Evergreen.V338.MessageView exposing (..)

import Date
import Duration
import Evergreen.V338.Coord
import Evergreen.V338.CssPixels
import Evergreen.V338.Emoji
import Evergreen.V338.NonemptyDict
import Evergreen.V338.Point2d
import Evergreen.V338.RichText
import Evergreen.V338.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V338.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V338.NonemptyDict.NonemptyDict Int Evergreen.V338.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V338.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V338.Point2d.Point2d Evergreen.V338.CssPixels.CssPixels Evergreen.V338.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V338.Point2d.Point2d Evergreen.V338.CssPixels.CssPixels Evergreen.V338.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V338.Point2d.Point2d Evergreen.V338.CssPixels.CssPixels Evergreen.V338.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V338.Point2d.Point2d Evergreen.V338.CssPixels.CssPixels Evergreen.V338.Touch.ScreenCoordinate) ( Float, Float )
