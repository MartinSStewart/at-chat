module Evergreen.V358.MessageView exposing (..)

import Date
import Duration
import Evergreen.V358.Coord
import Evergreen.V358.CssPixels
import Evergreen.V358.Discord
import Evergreen.V358.Emoji
import Evergreen.V358.Id
import Evergreen.V358.NonemptyDict
import Evergreen.V358.Point2d
import Evergreen.V358.RichText
import Evergreen.V358.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V358.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V358.NonemptyDict.NonemptyDict Int Evergreen.V358.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V358.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V358.Point2d.Point2d Evergreen.V358.CssPixels.CssPixels Evergreen.V358.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V358.Point2d.Point2d Evergreen.V358.CssPixels.CssPixels Evergreen.V358.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V358.Point2d.Point2d Evergreen.V358.CssPixels.CssPixels Evergreen.V358.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V358.Point2d.Point2d Evergreen.V358.CssPixels.CssPixels Evergreen.V358.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId)
