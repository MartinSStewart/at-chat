module Evergreen.V335.MessageView exposing (..)

import Date
import Duration
import Evergreen.V335.Coord
import Evergreen.V335.CssPixels
import Evergreen.V335.Emoji
import Evergreen.V335.NonemptyDict
import Evergreen.V335.Point2d
import Evergreen.V335.RichText
import Evergreen.V335.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V335.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V335.NonemptyDict.NonemptyDict Int Evergreen.V335.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V335.Coord.Coord Evergreen.V335.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V335.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V335.Point2d.Point2d Evergreen.V335.CssPixels.CssPixels Evergreen.V335.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V335.Point2d.Point2d Evergreen.V335.CssPixels.CssPixels Evergreen.V335.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V335.Point2d.Point2d Evergreen.V335.CssPixels.CssPixels Evergreen.V335.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V335.Point2d.Point2d Evergreen.V335.CssPixels.CssPixels Evergreen.V335.Touch.ScreenCoordinate) ( Float, Float )
