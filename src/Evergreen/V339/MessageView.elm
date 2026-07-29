module Evergreen.V339.MessageView exposing (..)

import Date
import Duration
import Evergreen.V339.Coord
import Evergreen.V339.CssPixels
import Evergreen.V339.Emoji
import Evergreen.V339.NonemptyDict
import Evergreen.V339.Point2d
import Evergreen.V339.RichText
import Evergreen.V339.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V339.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V339.NonemptyDict.NonemptyDict Int Evergreen.V339.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V339.Coord.Coord Evergreen.V339.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V339.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V339.Point2d.Point2d Evergreen.V339.CssPixels.CssPixels Evergreen.V339.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V339.Point2d.Point2d Evergreen.V339.CssPixels.CssPixels Evergreen.V339.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V339.Point2d.Point2d Evergreen.V339.CssPixels.CssPixels Evergreen.V339.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V339.Point2d.Point2d Evergreen.V339.CssPixels.CssPixels Evergreen.V339.Touch.ScreenCoordinate) ( Float, Float )
