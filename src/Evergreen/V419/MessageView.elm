module Evergreen.V419.MessageView exposing (..)

import Date
import Duration
import Evergreen.V419.Coord
import Evergreen.V419.CssPixels
import Evergreen.V419.Discord
import Evergreen.V419.Emoji
import Evergreen.V419.Id
import Evergreen.V419.NonemptyDict
import Evergreen.V419.Point2d
import Evergreen.V419.RichText
import Evergreen.V419.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V419.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V419.NonemptyDict.NonemptyDict Int Evergreen.V419.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V419.Coord.Coord Evergreen.V419.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V419.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V419.Point2d.Point2d Evergreen.V419.CssPixels.CssPixels Evergreen.V419.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V419.Point2d.Point2d Evergreen.V419.CssPixels.CssPixels Evergreen.V419.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V419.Point2d.Point2d Evergreen.V419.CssPixels.CssPixels Evergreen.V419.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V419.Point2d.Point2d Evergreen.V419.CssPixels.CssPixels Evergreen.V419.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) Evergreen.V419.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) Evergreen.V419.Id.ThreadRoute
    | MessageView_PressedCopyCode String
