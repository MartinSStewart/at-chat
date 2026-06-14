module Evergreen.V289.MessageView exposing (..)

import Date
import Duration
import Evergreen.V289.Coord
import Evergreen.V289.CssPixels
import Evergreen.V289.Emoji
import Evergreen.V289.NonemptyDict
import Evergreen.V289.Point2d
import Evergreen.V289.RichText
import Evergreen.V289.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V289.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V289.NonemptyDict.NonemptyDict Int Evergreen.V289.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V289.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V289.Point2d.Point2d Evergreen.V289.CssPixels.CssPixels Evergreen.V289.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V289.Point2d.Point2d Evergreen.V289.CssPixels.CssPixels Evergreen.V289.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V289.Point2d.Point2d Evergreen.V289.CssPixels.CssPixels Evergreen.V289.Touch.ScreenCoordinate) ( Float, Float )
