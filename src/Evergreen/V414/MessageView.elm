module Evergreen.V414.MessageView exposing (..)

import Date
import Duration
import Evergreen.V414.Coord
import Evergreen.V414.CssPixels
import Evergreen.V414.Discord
import Evergreen.V414.Emoji
import Evergreen.V414.Id
import Evergreen.V414.NonemptyDict
import Evergreen.V414.Point2d
import Evergreen.V414.RichText
import Evergreen.V414.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V414.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V414.NonemptyDict.NonemptyDict Int Evergreen.V414.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V414.Coord.Coord Evergreen.V414.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V414.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V414.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V414.Coord.Coord Evergreen.V414.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V414.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V414.Point2d.Point2d Evergreen.V414.CssPixels.CssPixels Evergreen.V414.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V414.Point2d.Point2d Evergreen.V414.CssPixels.CssPixels Evergreen.V414.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V414.Point2d.Point2d Evergreen.V414.CssPixels.CssPixels Evergreen.V414.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V414.Point2d.Point2d Evergreen.V414.CssPixels.CssPixels Evergreen.V414.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId) Evergreen.V414.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) Evergreen.V414.Id.ThreadRoute
    | MessageView_PressedCopyCode String
