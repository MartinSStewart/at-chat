module Evergreen.V394.MessageView exposing (..)

import Date
import Duration
import Evergreen.V394.Coord
import Evergreen.V394.CssPixels
import Evergreen.V394.Discord
import Evergreen.V394.Emoji
import Evergreen.V394.Id
import Evergreen.V394.NonemptyDict
import Evergreen.V394.Point2d
import Evergreen.V394.RichText
import Evergreen.V394.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V394.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V394.NonemptyDict.NonemptyDict Int Evergreen.V394.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V394.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V394.Point2d.Point2d Evergreen.V394.CssPixels.CssPixels Evergreen.V394.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V394.Point2d.Point2d Evergreen.V394.CssPixels.CssPixels Evergreen.V394.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V394.Point2d.Point2d Evergreen.V394.CssPixels.CssPixels Evergreen.V394.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V394.Point2d.Point2d Evergreen.V394.CssPixels.CssPixels Evergreen.V394.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId)
