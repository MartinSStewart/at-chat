module Evergreen.V389.MessageView exposing (..)

import Date
import Duration
import Evergreen.V389.Coord
import Evergreen.V389.CssPixels
import Evergreen.V389.Discord
import Evergreen.V389.Emoji
import Evergreen.V389.Id
import Evergreen.V389.NonemptyDict
import Evergreen.V389.Point2d
import Evergreen.V389.RichText
import Evergreen.V389.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V389.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V389.NonemptyDict.NonemptyDict Int Evergreen.V389.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V389.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V389.Point2d.Point2d Evergreen.V389.CssPixels.CssPixels Evergreen.V389.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V389.Point2d.Point2d Evergreen.V389.CssPixels.CssPixels Evergreen.V389.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V389.Point2d.Point2d Evergreen.V389.CssPixels.CssPixels Evergreen.V389.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V389.Point2d.Point2d Evergreen.V389.CssPixels.CssPixels Evergreen.V389.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId)
