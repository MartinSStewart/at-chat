module Evergreen.V298.MessageView exposing (..)

import Date
import Duration
import Evergreen.V298.Coord
import Evergreen.V298.CssPixels
import Evergreen.V298.Emoji
import Evergreen.V298.NonemptyDict
import Evergreen.V298.Point2d
import Evergreen.V298.RichText
import Evergreen.V298.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V298.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V298.NonemptyDict.NonemptyDict Int Evergreen.V298.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V298.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIcon (Evergreen.V298.Point2d.Point2d Evergreen.V298.CssPixels.CssPixels Evergreen.V298.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V298.Point2d.Point2d Evergreen.V298.CssPixels.CssPixels Evergreen.V298.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V298.Point2d.Point2d Evergreen.V298.CssPixels.CssPixels Evergreen.V298.Touch.ScreenCoordinate) ( Float, Float )
