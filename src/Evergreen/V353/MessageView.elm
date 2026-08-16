module Evergreen.V353.MessageView exposing (..)

import Date
import Duration
import Evergreen.V353.Coord
import Evergreen.V353.CssPixels
import Evergreen.V353.Discord
import Evergreen.V353.Emoji
import Evergreen.V353.Id
import Evergreen.V353.NonemptyDict
import Evergreen.V353.Point2d
import Evergreen.V353.RichText
import Evergreen.V353.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V353.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V353.NonemptyDict.NonemptyDict Int Evergreen.V353.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V353.Coord.Coord Evergreen.V353.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V353.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V353.Point2d.Point2d Evergreen.V353.CssPixels.CssPixels Evergreen.V353.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V353.Point2d.Point2d Evergreen.V353.CssPixels.CssPixels Evergreen.V353.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V353.Point2d.Point2d Evergreen.V353.CssPixels.CssPixels Evergreen.V353.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V353.Point2d.Point2d Evergreen.V353.CssPixels.CssPixels Evergreen.V353.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V353.Id.Id Evergreen.V353.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId)
