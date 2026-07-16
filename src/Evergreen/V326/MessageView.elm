module Evergreen.V326.MessageView exposing (..)

import Date
import Duration
import Evergreen.V326.Coord
import Evergreen.V326.CssPixels
import Evergreen.V326.Emoji
import Evergreen.V326.NonemptyDict
import Evergreen.V326.Point2d
import Evergreen.V326.RichText
import Evergreen.V326.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V326.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V326.NonemptyDict.NonemptyDict Int Evergreen.V326.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V326.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V326.Point2d.Point2d Evergreen.V326.CssPixels.CssPixels Evergreen.V326.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V326.Point2d.Point2d Evergreen.V326.CssPixels.CssPixels Evergreen.V326.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V326.Point2d.Point2d Evergreen.V326.CssPixels.CssPixels Evergreen.V326.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V326.Point2d.Point2d Evergreen.V326.CssPixels.CssPixels Evergreen.V326.Touch.ScreenCoordinate) ( Float, Float )
