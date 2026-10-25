module Evergreen.V411.MessageView exposing (..)

import Date
import Duration
import Evergreen.V411.Coord
import Evergreen.V411.CssPixels
import Evergreen.V411.Discord
import Evergreen.V411.Emoji
import Evergreen.V411.Id
import Evergreen.V411.NonemptyDict
import Evergreen.V411.Point2d
import Evergreen.V411.RichText
import Evergreen.V411.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V411.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V411.NonemptyDict.NonemptyDict Int Evergreen.V411.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V411.Coord.Coord Evergreen.V411.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V411.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V411.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V411.Coord.Coord Evergreen.V411.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V411.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V411.Point2d.Point2d Evergreen.V411.CssPixels.CssPixels Evergreen.V411.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V411.Point2d.Point2d Evergreen.V411.CssPixels.CssPixels Evergreen.V411.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V411.Point2d.Point2d Evergreen.V411.CssPixels.CssPixels Evergreen.V411.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V411.Point2d.Point2d Evergreen.V411.CssPixels.CssPixels Evergreen.V411.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId) Evergreen.V411.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) Evergreen.V411.Id.ThreadRoute
    | MessageView_PressedCopyCode String
