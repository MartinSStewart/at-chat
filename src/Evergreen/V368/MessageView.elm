module Evergreen.V368.MessageView exposing (..)

import Date
import Duration
import Evergreen.V368.Coord
import Evergreen.V368.CssPixels
import Evergreen.V368.Discord
import Evergreen.V368.Emoji
import Evergreen.V368.Id
import Evergreen.V368.NonemptyDict
import Evergreen.V368.Point2d
import Evergreen.V368.RichText
import Evergreen.V368.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V368.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V368.NonemptyDict.NonemptyDict Int Evergreen.V368.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V368.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V368.Point2d.Point2d Evergreen.V368.CssPixels.CssPixels Evergreen.V368.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V368.Point2d.Point2d Evergreen.V368.CssPixels.CssPixels Evergreen.V368.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V368.Point2d.Point2d Evergreen.V368.CssPixels.CssPixels Evergreen.V368.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V368.Point2d.Point2d Evergreen.V368.CssPixels.CssPixels Evergreen.V368.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId)
