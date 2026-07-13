module Evergreen.V318.MessageView exposing (..)

import Date
import Duration
import Evergreen.V318.Coord
import Evergreen.V318.CssPixels
import Evergreen.V318.Emoji
import Evergreen.V318.NonemptyDict
import Evergreen.V318.Point2d
import Evergreen.V318.RichText
import Evergreen.V318.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V318.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V318.NonemptyDict.NonemptyDict Int Evergreen.V318.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V318.Coord.Coord Evergreen.V318.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V318.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V318.Point2d.Point2d Evergreen.V318.CssPixels.CssPixels Evergreen.V318.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V318.Point2d.Point2d Evergreen.V318.CssPixels.CssPixels Evergreen.V318.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V318.Point2d.Point2d Evergreen.V318.CssPixels.CssPixels Evergreen.V318.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V318.Point2d.Point2d Evergreen.V318.CssPixels.CssPixels Evergreen.V318.Touch.ScreenCoordinate) ( Float, Float )
