module Evergreen.V296.MessageView exposing (..)

import Date
import Duration
import Evergreen.V296.Coord
import Evergreen.V296.CssPixels
import Evergreen.V296.Emoji
import Evergreen.V296.NonemptyDict
import Evergreen.V296.Point2d
import Evergreen.V296.RichText
import Evergreen.V296.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V296.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V296.NonemptyDict.NonemptyDict Int Evergreen.V296.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V296.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V296.Point2d.Point2d Evergreen.V296.CssPixels.CssPixels Evergreen.V296.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V296.Point2d.Point2d Evergreen.V296.CssPixels.CssPixels Evergreen.V296.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V296.Point2d.Point2d Evergreen.V296.CssPixels.CssPixels Evergreen.V296.Touch.ScreenCoordinate) ( Float, Float )
