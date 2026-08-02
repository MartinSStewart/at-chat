module Evergreen.V343.MessageView exposing (..)

import Date
import Duration
import Evergreen.V343.Coord
import Evergreen.V343.CssPixels
import Evergreen.V343.Discord
import Evergreen.V343.Emoji
import Evergreen.V343.Id
import Evergreen.V343.NonemptyDict
import Evergreen.V343.Point2d
import Evergreen.V343.RichText
import Evergreen.V343.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V343.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V343.NonemptyDict.NonemptyDict Int Evergreen.V343.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V343.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V343.Point2d.Point2d Evergreen.V343.CssPixels.CssPixels Evergreen.V343.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V343.Point2d.Point2d Evergreen.V343.CssPixels.CssPixels Evergreen.V343.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V343.Point2d.Point2d Evergreen.V343.CssPixels.CssPixels Evergreen.V343.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V343.Point2d.Point2d Evergreen.V343.CssPixels.CssPixels Evergreen.V343.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId)
