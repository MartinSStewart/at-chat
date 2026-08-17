module Evergreen.V354.MessageView exposing (..)

import Date
import Duration
import Evergreen.V354.Coord
import Evergreen.V354.CssPixels
import Evergreen.V354.Discord
import Evergreen.V354.Emoji
import Evergreen.V354.Id
import Evergreen.V354.NonemptyDict
import Evergreen.V354.Point2d
import Evergreen.V354.RichText
import Evergreen.V354.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V354.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V354.NonemptyDict.NonemptyDict Int Evergreen.V354.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V354.Coord.Coord Evergreen.V354.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V354.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V354.Point2d.Point2d Evergreen.V354.CssPixels.CssPixels Evergreen.V354.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V354.Point2d.Point2d Evergreen.V354.CssPixels.CssPixels Evergreen.V354.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V354.Point2d.Point2d Evergreen.V354.CssPixels.CssPixels Evergreen.V354.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V354.Point2d.Point2d Evergreen.V354.CssPixels.CssPixels Evergreen.V354.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId)
