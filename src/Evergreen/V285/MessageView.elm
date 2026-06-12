module Evergreen.V285.MessageView exposing (..)

import Date
import Duration
import Evergreen.V285.Coord
import Evergreen.V285.CssPixels
import Evergreen.V285.Emoji
import Evergreen.V285.NonemptyDict
import Evergreen.V285.Point2d
import Evergreen.V285.RichText
import Evergreen.V285.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V285.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V285.NonemptyDict.NonemptyDict Int Evergreen.V285.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V285.Coord.Coord Evergreen.V285.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V285.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V285.Point2d.Point2d Evergreen.V285.CssPixels.CssPixels Evergreen.V285.Touch.ScreenCoordinate)
    | MessageView_PressedTimestamp (Evergreen.V285.Point2d.Point2d Evergreen.V285.CssPixels.CssPixels Evergreen.V285.Touch.ScreenCoordinate)
    | MessageView_PressedDateDivider Date.Date (Evergreen.V285.Point2d.Point2d Evergreen.V285.CssPixels.CssPixels Evergreen.V285.Touch.ScreenCoordinate)
