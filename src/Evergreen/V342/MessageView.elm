module Evergreen.V342.MessageView exposing (..)

import Date
import Duration
import Evergreen.V342.Coord
import Evergreen.V342.CssPixels
import Evergreen.V342.Discord
import Evergreen.V342.Emoji
import Evergreen.V342.Id
import Evergreen.V342.NonemptyDict
import Evergreen.V342.Point2d
import Evergreen.V342.RichText
import Evergreen.V342.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V342.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V342.NonemptyDict.NonemptyDict Int Evergreen.V342.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V342.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V342.Point2d.Point2d Evergreen.V342.CssPixels.CssPixels Evergreen.V342.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V342.Point2d.Point2d Evergreen.V342.CssPixels.CssPixels Evergreen.V342.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V342.Point2d.Point2d Evergreen.V342.CssPixels.CssPixels Evergreen.V342.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V342.Point2d.Point2d Evergreen.V342.CssPixels.CssPixels Evergreen.V342.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId)
