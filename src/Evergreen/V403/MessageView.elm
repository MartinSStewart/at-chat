module Evergreen.V403.MessageView exposing (..)

import Date
import Duration
import Evergreen.V403.Coord
import Evergreen.V403.CssPixels
import Evergreen.V403.Discord
import Evergreen.V403.Emoji
import Evergreen.V403.Id
import Evergreen.V403.NonemptyDict
import Evergreen.V403.Point2d
import Evergreen.V403.RichText
import Evergreen.V403.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V403.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V403.NonemptyDict.NonemptyDict Int Evergreen.V403.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V403.Coord.Coord Evergreen.V403.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V403.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V403.Point2d.Point2d Evergreen.V403.CssPixels.CssPixels Evergreen.V403.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V403.Point2d.Point2d Evergreen.V403.CssPixels.CssPixels Evergreen.V403.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V403.Point2d.Point2d Evergreen.V403.CssPixels.CssPixels Evergreen.V403.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V403.Point2d.Point2d Evergreen.V403.CssPixels.CssPixels Evergreen.V403.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) Evergreen.V403.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) Evergreen.V403.Id.ThreadRoute
    | MessageView_PressedCopyCode String
