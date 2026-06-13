module Evergreen.V287.MessageView exposing (..)

import Date
import Duration
import Evergreen.V287.Coord
import Evergreen.V287.CssPixels
import Evergreen.V287.Emoji
import Evergreen.V287.NonemptyDict
import Evergreen.V287.Point2d
import Evergreen.V287.RichText
import Evergreen.V287.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V287.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V287.NonemptyDict.NonemptyDict Int Evergreen.V287.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V287.Coord.Coord Evergreen.V287.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V287.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGoMatchStartedCard
    | MessageView_PressedUserIcon (Evergreen.V287.Point2d.Point2d Evergreen.V287.CssPixels.CssPixels Evergreen.V287.Touch.ScreenCoordinate)
    | MessageView_PressedTimestamp (Evergreen.V287.Point2d.Point2d Evergreen.V287.CssPixels.CssPixels Evergreen.V287.Touch.ScreenCoordinate)
    | MessageView_PressedDateDivider Date.Date (Evergreen.V287.Point2d.Point2d Evergreen.V287.CssPixels.CssPixels Evergreen.V287.Touch.ScreenCoordinate)
