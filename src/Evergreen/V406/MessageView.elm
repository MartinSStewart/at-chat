module Evergreen.V406.MessageView exposing (..)

import Date
import Duration
import Evergreen.V406.Coord
import Evergreen.V406.CssPixels
import Evergreen.V406.Discord
import Evergreen.V406.Emoji
import Evergreen.V406.Id
import Evergreen.V406.NonemptyDict
import Evergreen.V406.Point2d
import Evergreen.V406.RichText
import Evergreen.V406.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V406.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V406.NonemptyDict.NonemptyDict Int Evergreen.V406.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V406.Coord.Coord Evergreen.V406.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V406.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V406.Point2d.Point2d Evergreen.V406.CssPixels.CssPixels Evergreen.V406.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V406.Point2d.Point2d Evergreen.V406.CssPixels.CssPixels Evergreen.V406.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V406.Point2d.Point2d Evergreen.V406.CssPixels.CssPixels Evergreen.V406.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V406.Point2d.Point2d Evergreen.V406.CssPixels.CssPixels Evergreen.V406.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V406.Id.Id Evergreen.V406.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) Evergreen.V406.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) Evergreen.V406.Id.ThreadRoute
    | MessageView_PressedCopyCode String
