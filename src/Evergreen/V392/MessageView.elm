module Evergreen.V392.MessageView exposing (..)

import Date
import Duration
import Evergreen.V392.Coord
import Evergreen.V392.CssPixels
import Evergreen.V392.Discord
import Evergreen.V392.Emoji
import Evergreen.V392.Id
import Evergreen.V392.NonemptyDict
import Evergreen.V392.Point2d
import Evergreen.V392.RichText
import Evergreen.V392.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V392.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V392.NonemptyDict.NonemptyDict Int Evergreen.V392.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V392.Coord.Coord Evergreen.V392.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V392.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V392.Point2d.Point2d Evergreen.V392.CssPixels.CssPixels Evergreen.V392.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V392.Point2d.Point2d Evergreen.V392.CssPixels.CssPixels Evergreen.V392.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V392.Point2d.Point2d Evergreen.V392.CssPixels.CssPixels Evergreen.V392.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V392.Point2d.Point2d Evergreen.V392.CssPixels.CssPixels Evergreen.V392.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V392.Discord.Id Evergreen.V392.Discord.UserId)
