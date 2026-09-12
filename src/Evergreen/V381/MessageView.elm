module Evergreen.V381.MessageView exposing (..)

import Date
import Duration
import Evergreen.V381.Coord
import Evergreen.V381.CssPixels
import Evergreen.V381.Discord
import Evergreen.V381.Emoji
import Evergreen.V381.Id
import Evergreen.V381.NonemptyDict
import Evergreen.V381.Point2d
import Evergreen.V381.RichText
import Evergreen.V381.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V381.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V381.NonemptyDict.NonemptyDict Int Evergreen.V381.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V381.Coord.Coord Evergreen.V381.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V381.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V381.Point2d.Point2d Evergreen.V381.CssPixels.CssPixels Evergreen.V381.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V381.Point2d.Point2d Evergreen.V381.CssPixels.CssPixels Evergreen.V381.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V381.Point2d.Point2d Evergreen.V381.CssPixels.CssPixels Evergreen.V381.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V381.Point2d.Point2d Evergreen.V381.CssPixels.CssPixels Evergreen.V381.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId)
