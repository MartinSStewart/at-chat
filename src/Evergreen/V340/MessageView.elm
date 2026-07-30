module Evergreen.V340.MessageView exposing (..)

import Date
import Duration
import Evergreen.V340.Coord
import Evergreen.V340.CssPixels
import Evergreen.V340.Discord
import Evergreen.V340.Emoji
import Evergreen.V340.Id
import Evergreen.V340.NonemptyDict
import Evergreen.V340.Point2d
import Evergreen.V340.RichText
import Evergreen.V340.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V340.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V340.NonemptyDict.NonemptyDict Int Evergreen.V340.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V340.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V340.Point2d.Point2d Evergreen.V340.CssPixels.CssPixels Evergreen.V340.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V340.Point2d.Point2d Evergreen.V340.CssPixels.CssPixels Evergreen.V340.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V340.Point2d.Point2d Evergreen.V340.CssPixels.CssPixels Evergreen.V340.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V340.Point2d.Point2d Evergreen.V340.CssPixels.CssPixels Evergreen.V340.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId)
