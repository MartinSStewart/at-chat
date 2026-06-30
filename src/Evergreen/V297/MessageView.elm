module Evergreen.V297.MessageView exposing (..)

import Date
import Duration
import Evergreen.V297.Coord
import Evergreen.V297.CssPixels
import Evergreen.V297.Emoji
import Evergreen.V297.NonemptyDict
import Evergreen.V297.Point2d
import Evergreen.V297.RichText
import Evergreen.V297.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V297.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V297.NonemptyDict.NonemptyDict Int Evergreen.V297.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V297.Coord.Coord Evergreen.V297.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V297.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V297.Point2d.Point2d Evergreen.V297.CssPixels.CssPixels Evergreen.V297.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V297.Point2d.Point2d Evergreen.V297.CssPixels.CssPixels Evergreen.V297.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V297.Point2d.Point2d Evergreen.V297.CssPixels.CssPixels Evergreen.V297.Touch.ScreenCoordinate) ( Float, Float )
