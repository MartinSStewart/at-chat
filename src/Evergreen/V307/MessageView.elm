module Evergreen.V307.MessageView exposing (..)

import Date
import Duration
import Evergreen.V307.Coord
import Evergreen.V307.CssPixels
import Evergreen.V307.Emoji
import Evergreen.V307.NonemptyDict
import Evergreen.V307.Point2d
import Evergreen.V307.RichText
import Evergreen.V307.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V307.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V307.NonemptyDict.NonemptyDict Int Evergreen.V307.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V307.Coord.Coord Evergreen.V307.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V307.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V307.Point2d.Point2d Evergreen.V307.CssPixels.CssPixels Evergreen.V307.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V307.Point2d.Point2d Evergreen.V307.CssPixels.CssPixels Evergreen.V307.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V307.Point2d.Point2d Evergreen.V307.CssPixels.CssPixels Evergreen.V307.Touch.ScreenCoordinate) ( Float, Float )
