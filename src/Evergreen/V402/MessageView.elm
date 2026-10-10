module Evergreen.V402.MessageView exposing (..)

import Date
import Duration
import Evergreen.V402.Coord
import Evergreen.V402.CssPixels
import Evergreen.V402.Discord
import Evergreen.V402.Emoji
import Evergreen.V402.Id
import Evergreen.V402.NonemptyDict
import Evergreen.V402.Point2d
import Evergreen.V402.RichText
import Evergreen.V402.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V402.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V402.NonemptyDict.NonemptyDict Int Evergreen.V402.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V402.Coord.Coord Evergreen.V402.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V402.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V402.Point2d.Point2d Evergreen.V402.CssPixels.CssPixels Evergreen.V402.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V402.Point2d.Point2d Evergreen.V402.CssPixels.CssPixels Evergreen.V402.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V402.Point2d.Point2d Evergreen.V402.CssPixels.CssPixels Evergreen.V402.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V402.Point2d.Point2d Evergreen.V402.CssPixels.CssPixels Evergreen.V402.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) Evergreen.V402.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) Evergreen.V402.Id.ThreadRoute
    | MessageView_PressedCopyCode String
