module Evergreen.V409.MessageView exposing (..)

import Date
import Duration
import Evergreen.V409.Coord
import Evergreen.V409.CssPixels
import Evergreen.V409.Discord
import Evergreen.V409.Emoji
import Evergreen.V409.Id
import Evergreen.V409.NonemptyDict
import Evergreen.V409.Point2d
import Evergreen.V409.RichText
import Evergreen.V409.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V409.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V409.NonemptyDict.NonemptyDict Int Evergreen.V409.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V409.Coord.Coord Evergreen.V409.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V409.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V409.Point2d.Point2d Evergreen.V409.CssPixels.CssPixels Evergreen.V409.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V409.Point2d.Point2d Evergreen.V409.CssPixels.CssPixels Evergreen.V409.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V409.Point2d.Point2d Evergreen.V409.CssPixels.CssPixels Evergreen.V409.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V409.Point2d.Point2d Evergreen.V409.CssPixels.CssPixels Evergreen.V409.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) Evergreen.V409.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) Evergreen.V409.Id.ThreadRoute
    | MessageView_PressedCopyCode String
