module Evergreen.V336.MessageView exposing (..)

import Date
import Duration
import Evergreen.V336.Coord
import Evergreen.V336.CssPixels
import Evergreen.V336.Emoji
import Evergreen.V336.NonemptyDict
import Evergreen.V336.Point2d
import Evergreen.V336.RichText
import Evergreen.V336.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V336.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V336.NonemptyDict.NonemptyDict Int Evergreen.V336.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V336.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V336.Point2d.Point2d Evergreen.V336.CssPixels.CssPixels Evergreen.V336.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V336.Point2d.Point2d Evergreen.V336.CssPixels.CssPixels Evergreen.V336.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V336.Point2d.Point2d Evergreen.V336.CssPixels.CssPixels Evergreen.V336.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V336.Point2d.Point2d Evergreen.V336.CssPixels.CssPixels Evergreen.V336.Touch.ScreenCoordinate) ( Float, Float )
