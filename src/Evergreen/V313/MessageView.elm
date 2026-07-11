module Evergreen.V313.MessageView exposing (..)

import Date
import Duration
import Evergreen.V313.Coord
import Evergreen.V313.CssPixels
import Evergreen.V313.Emoji
import Evergreen.V313.NonemptyDict
import Evergreen.V313.Point2d
import Evergreen.V313.RichText
import Evergreen.V313.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V313.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V313.NonemptyDict.NonemptyDict Int Evergreen.V313.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V313.Coord.Coord Evergreen.V313.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V313.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V313.Point2d.Point2d Evergreen.V313.CssPixels.CssPixels Evergreen.V313.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V313.Point2d.Point2d Evergreen.V313.CssPixels.CssPixels Evergreen.V313.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V313.Point2d.Point2d Evergreen.V313.CssPixels.CssPixels Evergreen.V313.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V313.Point2d.Point2d Evergreen.V313.CssPixels.CssPixels Evergreen.V313.Touch.ScreenCoordinate) ( Float, Float )
