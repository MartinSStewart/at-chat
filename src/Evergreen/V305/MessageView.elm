module Evergreen.V305.MessageView exposing (..)

import Date
import Duration
import Evergreen.V305.Coord
import Evergreen.V305.CssPixels
import Evergreen.V305.Emoji
import Evergreen.V305.NonemptyDict
import Evergreen.V305.Point2d
import Evergreen.V305.RichText
import Evergreen.V305.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V305.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V305.NonemptyDict.NonemptyDict Int Evergreen.V305.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V305.Coord.Coord Evergreen.V305.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V305.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V305.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V305.Coord.Coord Evergreen.V305.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V305.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V305.Point2d.Point2d Evergreen.V305.CssPixels.CssPixels Evergreen.V305.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V305.Point2d.Point2d Evergreen.V305.CssPixels.CssPixels Evergreen.V305.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V305.Point2d.Point2d Evergreen.V305.CssPixels.CssPixels Evergreen.V305.Touch.ScreenCoordinate) ( Float, Float )
