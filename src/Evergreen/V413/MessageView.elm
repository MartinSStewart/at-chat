module Evergreen.V413.MessageView exposing (..)

import Date
import Duration
import Evergreen.V413.Coord
import Evergreen.V413.CssPixels
import Evergreen.V413.Discord
import Evergreen.V413.Emoji
import Evergreen.V413.Id
import Evergreen.V413.NonemptyDict
import Evergreen.V413.Point2d
import Evergreen.V413.RichText
import Evergreen.V413.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V413.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V413.NonemptyDict.NonemptyDict Int Evergreen.V413.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V413.Coord.Coord Evergreen.V413.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V413.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V413.Point2d.Point2d Evergreen.V413.CssPixels.CssPixels Evergreen.V413.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V413.Point2d.Point2d Evergreen.V413.CssPixels.CssPixels Evergreen.V413.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V413.Point2d.Point2d Evergreen.V413.CssPixels.CssPixels Evergreen.V413.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V413.Point2d.Point2d Evergreen.V413.CssPixels.CssPixels Evergreen.V413.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) Evergreen.V413.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) Evergreen.V413.Id.ThreadRoute
    | MessageView_PressedCopyCode String
