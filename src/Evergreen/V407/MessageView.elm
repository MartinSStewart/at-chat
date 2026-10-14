module Evergreen.V407.MessageView exposing (..)

import Date
import Duration
import Evergreen.V407.Coord
import Evergreen.V407.CssPixels
import Evergreen.V407.Discord
import Evergreen.V407.Emoji
import Evergreen.V407.Id
import Evergreen.V407.NonemptyDict
import Evergreen.V407.Point2d
import Evergreen.V407.RichText
import Evergreen.V407.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V407.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V407.NonemptyDict.NonemptyDict Int Evergreen.V407.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V407.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V407.Point2d.Point2d Evergreen.V407.CssPixels.CssPixels Evergreen.V407.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V407.Point2d.Point2d Evergreen.V407.CssPixels.CssPixels Evergreen.V407.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V407.Point2d.Point2d Evergreen.V407.CssPixels.CssPixels Evergreen.V407.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V407.Point2d.Point2d Evergreen.V407.CssPixels.CssPixels Evergreen.V407.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) Evergreen.V407.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) Evergreen.V407.Id.ThreadRoute
    | MessageView_PressedCopyCode String
