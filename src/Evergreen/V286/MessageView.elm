module Evergreen.V286.MessageView exposing (..)

import Date
import Duration
import Evergreen.V286.Coord
import Evergreen.V286.CssPixels
import Evergreen.V286.Emoji
import Evergreen.V286.NonemptyDict
import Evergreen.V286.Point2d
import Evergreen.V286.RichText
import Evergreen.V286.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V286.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V286.NonemptyDict.NonemptyDict Int Evergreen.V286.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V286.Coord.Coord Evergreen.V286.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V286.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V286.Point2d.Point2d Evergreen.V286.CssPixels.CssPixels Evergreen.V286.Touch.ScreenCoordinate)
    | MessageView_PressedTimestamp (Evergreen.V286.Point2d.Point2d Evergreen.V286.CssPixels.CssPixels Evergreen.V286.Touch.ScreenCoordinate)
    | MessageView_PressedDateDivider Date.Date (Evergreen.V286.Point2d.Point2d Evergreen.V286.CssPixels.CssPixels Evergreen.V286.Touch.ScreenCoordinate)
