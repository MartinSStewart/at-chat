module Evergreen.V290.MessageView exposing (..)

import Date
import Duration
import Evergreen.V290.Coord
import Evergreen.V290.CssPixels
import Evergreen.V290.Emoji
import Evergreen.V290.NonemptyDict
import Evergreen.V290.Point2d
import Evergreen.V290.RichText
import Evergreen.V290.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V290.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V290.NonemptyDict.NonemptyDict Int Evergreen.V290.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V290.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V290.Point2d.Point2d Evergreen.V290.CssPixels.CssPixels Evergreen.V290.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V290.Point2d.Point2d Evergreen.V290.CssPixels.CssPixels Evergreen.V290.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V290.Point2d.Point2d Evergreen.V290.CssPixels.CssPixels Evergreen.V290.Touch.ScreenCoordinate) ( Float, Float )
