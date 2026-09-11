module Evergreen.V378.MessageView exposing (..)

import Date
import Duration
import Evergreen.V378.Coord
import Evergreen.V378.CssPixels
import Evergreen.V378.Discord
import Evergreen.V378.Emoji
import Evergreen.V378.Id
import Evergreen.V378.NonemptyDict
import Evergreen.V378.Point2d
import Evergreen.V378.RichText
import Evergreen.V378.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V378.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V378.NonemptyDict.NonemptyDict Int Evergreen.V378.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V378.Coord.Coord Evergreen.V378.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V378.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V378.Point2d.Point2d Evergreen.V378.CssPixels.CssPixels Evergreen.V378.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V378.Point2d.Point2d Evergreen.V378.CssPixels.CssPixels Evergreen.V378.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V378.Point2d.Point2d Evergreen.V378.CssPixels.CssPixels Evergreen.V378.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V378.Point2d.Point2d Evergreen.V378.CssPixels.CssPixels Evergreen.V378.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId)
