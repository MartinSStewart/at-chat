module Evergreen.V301.MessageView exposing (..)

import Date
import Duration
import Evergreen.V301.Coord
import Evergreen.V301.CssPixels
import Evergreen.V301.Emoji
import Evergreen.V301.NonemptyDict
import Evergreen.V301.Point2d
import Evergreen.V301.RichText
import Evergreen.V301.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V301.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V301.NonemptyDict.NonemptyDict Int Evergreen.V301.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V301.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V301.Point2d.Point2d Evergreen.V301.CssPixels.CssPixels Evergreen.V301.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V301.Point2d.Point2d Evergreen.V301.CssPixels.CssPixels Evergreen.V301.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V301.Point2d.Point2d Evergreen.V301.CssPixels.CssPixels Evergreen.V301.Touch.ScreenCoordinate) ( Float, Float )
