module Evergreen.V377.MessageView exposing (..)

import Date
import Duration
import Evergreen.V377.Coord
import Evergreen.V377.CssPixels
import Evergreen.V377.Discord
import Evergreen.V377.Emoji
import Evergreen.V377.Id
import Evergreen.V377.NonemptyDict
import Evergreen.V377.Point2d
import Evergreen.V377.RichText
import Evergreen.V377.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V377.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V377.NonemptyDict.NonemptyDict Int Evergreen.V377.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V377.Coord.Coord Evergreen.V377.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V377.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V377.Point2d.Point2d Evergreen.V377.CssPixels.CssPixels Evergreen.V377.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V377.Point2d.Point2d Evergreen.V377.CssPixels.CssPixels Evergreen.V377.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V377.Point2d.Point2d Evergreen.V377.CssPixels.CssPixels Evergreen.V377.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V377.Point2d.Point2d Evergreen.V377.CssPixels.CssPixels Evergreen.V377.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId)
