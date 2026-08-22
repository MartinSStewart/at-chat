module Evergreen.V360.MessageView exposing (..)

import Date
import Duration
import Evergreen.V360.Coord
import Evergreen.V360.CssPixels
import Evergreen.V360.Discord
import Evergreen.V360.Emoji
import Evergreen.V360.Id
import Evergreen.V360.NonemptyDict
import Evergreen.V360.Point2d
import Evergreen.V360.RichText
import Evergreen.V360.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V360.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V360.NonemptyDict.NonemptyDict Int Evergreen.V360.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V360.Coord.Coord Evergreen.V360.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V360.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V360.Point2d.Point2d Evergreen.V360.CssPixels.CssPixels Evergreen.V360.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V360.Point2d.Point2d Evergreen.V360.CssPixels.CssPixels Evergreen.V360.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V360.Point2d.Point2d Evergreen.V360.CssPixels.CssPixels Evergreen.V360.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V360.Point2d.Point2d Evergreen.V360.CssPixels.CssPixels Evergreen.V360.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId)
