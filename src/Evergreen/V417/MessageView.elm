module Evergreen.V417.MessageView exposing (..)

import Date
import Duration
import Evergreen.V417.Coord
import Evergreen.V417.CssPixels
import Evergreen.V417.Discord
import Evergreen.V417.Emoji
import Evergreen.V417.Id
import Evergreen.V417.NonemptyDict
import Evergreen.V417.Point2d
import Evergreen.V417.RichText
import Evergreen.V417.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V417.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V417.NonemptyDict.NonemptyDict Int Evergreen.V417.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V417.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V417.Point2d.Point2d Evergreen.V417.CssPixels.CssPixels Evergreen.V417.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V417.Point2d.Point2d Evergreen.V417.CssPixels.CssPixels Evergreen.V417.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V417.Point2d.Point2d Evergreen.V417.CssPixels.CssPixels Evergreen.V417.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V417.Point2d.Point2d Evergreen.V417.CssPixels.CssPixels Evergreen.V417.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) Evergreen.V417.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) Evergreen.V417.Id.ThreadRoute
    | MessageView_PressedCopyCode String
