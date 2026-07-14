module Evergreen.V319.MessageView exposing (..)

import Date
import Duration
import Evergreen.V319.Coord
import Evergreen.V319.CssPixels
import Evergreen.V319.Emoji
import Evergreen.V319.NonemptyDict
import Evergreen.V319.Point2d
import Evergreen.V319.RichText
import Evergreen.V319.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V319.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V319.NonemptyDict.NonemptyDict Int Evergreen.V319.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V319.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V319.Point2d.Point2d Evergreen.V319.CssPixels.CssPixels Evergreen.V319.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V319.Point2d.Point2d Evergreen.V319.CssPixels.CssPixels Evergreen.V319.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V319.Point2d.Point2d Evergreen.V319.CssPixels.CssPixels Evergreen.V319.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V319.Point2d.Point2d Evergreen.V319.CssPixels.CssPixels Evergreen.V319.Touch.ScreenCoordinate) ( Float, Float )
