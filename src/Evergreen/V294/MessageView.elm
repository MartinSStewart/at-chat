module Evergreen.V294.MessageView exposing (..)

import Date
import Duration
import Evergreen.V294.Coord
import Evergreen.V294.CssPixels
import Evergreen.V294.Emoji
import Evergreen.V294.NonemptyDict
import Evergreen.V294.Point2d
import Evergreen.V294.RichText
import Evergreen.V294.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V294.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V294.NonemptyDict.NonemptyDict Int Evergreen.V294.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V294.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V294.Point2d.Point2d Evergreen.V294.CssPixels.CssPixels Evergreen.V294.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V294.Point2d.Point2d Evergreen.V294.CssPixels.CssPixels Evergreen.V294.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V294.Point2d.Point2d Evergreen.V294.CssPixels.CssPixels Evergreen.V294.Touch.ScreenCoordinate) ( Float, Float )
