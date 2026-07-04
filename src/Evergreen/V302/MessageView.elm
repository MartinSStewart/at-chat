module Evergreen.V302.MessageView exposing (..)

import Date
import Duration
import Evergreen.V302.Coord
import Evergreen.V302.CssPixels
import Evergreen.V302.Emoji
import Evergreen.V302.NonemptyDict
import Evergreen.V302.Point2d
import Evergreen.V302.RichText
import Evergreen.V302.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V302.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V302.NonemptyDict.NonemptyDict Int Evergreen.V302.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V302.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V302.Point2d.Point2d Evergreen.V302.CssPixels.CssPixels Evergreen.V302.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V302.Point2d.Point2d Evergreen.V302.CssPixels.CssPixels Evergreen.V302.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V302.Point2d.Point2d Evergreen.V302.CssPixels.CssPixels Evergreen.V302.Touch.ScreenCoordinate) ( Float, Float )
