module Evergreen.V295.MessageView exposing (..)

import Date
import Duration
import Evergreen.V295.Coord
import Evergreen.V295.CssPixels
import Evergreen.V295.Emoji
import Evergreen.V295.NonemptyDict
import Evergreen.V295.Point2d
import Evergreen.V295.RichText
import Evergreen.V295.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V295.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V295.NonemptyDict.NonemptyDict Int Evergreen.V295.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V295.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V295.Point2d.Point2d Evergreen.V295.CssPixels.CssPixels Evergreen.V295.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V295.Point2d.Point2d Evergreen.V295.CssPixels.CssPixels Evergreen.V295.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V295.Point2d.Point2d Evergreen.V295.CssPixels.CssPixels Evergreen.V295.Touch.ScreenCoordinate) ( Float, Float )
