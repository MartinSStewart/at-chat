module Evergreen.V405.MessageView exposing (..)

import Date
import Duration
import Evergreen.V405.Coord
import Evergreen.V405.CssPixels
import Evergreen.V405.Discord
import Evergreen.V405.Emoji
import Evergreen.V405.Id
import Evergreen.V405.NonemptyDict
import Evergreen.V405.Point2d
import Evergreen.V405.RichText
import Evergreen.V405.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V405.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V405.NonemptyDict.NonemptyDict Int Evergreen.V405.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V405.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V405.Point2d.Point2d Evergreen.V405.CssPixels.CssPixels Evergreen.V405.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V405.Point2d.Point2d Evergreen.V405.CssPixels.CssPixels Evergreen.V405.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V405.Point2d.Point2d Evergreen.V405.CssPixels.CssPixels Evergreen.V405.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V405.Point2d.Point2d Evergreen.V405.CssPixels.CssPixels Evergreen.V405.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) Evergreen.V405.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) Evergreen.V405.Id.ThreadRoute
    | MessageView_PressedCopyCode String
