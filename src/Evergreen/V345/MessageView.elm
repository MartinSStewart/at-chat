module Evergreen.V345.MessageView exposing (..)

import Date
import Duration
import Evergreen.V345.Coord
import Evergreen.V345.CssPixels
import Evergreen.V345.Discord
import Evergreen.V345.Emoji
import Evergreen.V345.Id
import Evergreen.V345.NonemptyDict
import Evergreen.V345.Point2d
import Evergreen.V345.RichText
import Evergreen.V345.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V345.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V345.NonemptyDict.NonemptyDict Int Evergreen.V345.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V345.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V345.Point2d.Point2d Evergreen.V345.CssPixels.CssPixels Evergreen.V345.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V345.Point2d.Point2d Evergreen.V345.CssPixels.CssPixels Evergreen.V345.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V345.Point2d.Point2d Evergreen.V345.CssPixels.CssPixels Evergreen.V345.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V345.Point2d.Point2d Evergreen.V345.CssPixels.CssPixels Evergreen.V345.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId)
