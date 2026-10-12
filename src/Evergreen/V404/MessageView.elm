module Evergreen.V404.MessageView exposing (..)

import Date
import Duration
import Evergreen.V404.Coord
import Evergreen.V404.CssPixels
import Evergreen.V404.Discord
import Evergreen.V404.Emoji
import Evergreen.V404.Id
import Evergreen.V404.NonemptyDict
import Evergreen.V404.Point2d
import Evergreen.V404.RichText
import Evergreen.V404.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V404.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V404.NonemptyDict.NonemptyDict Int Evergreen.V404.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V404.Coord.Coord Evergreen.V404.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V404.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V404.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V404.Coord.Coord Evergreen.V404.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V404.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V404.Point2d.Point2d Evergreen.V404.CssPixels.CssPixels Evergreen.V404.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V404.Point2d.Point2d Evergreen.V404.CssPixels.CssPixels Evergreen.V404.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V404.Point2d.Point2d Evergreen.V404.CssPixels.CssPixels Evergreen.V404.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V404.Point2d.Point2d Evergreen.V404.CssPixels.CssPixels Evergreen.V404.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId) Evergreen.V404.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) Evergreen.V404.Id.ThreadRoute
    | MessageView_PressedCopyCode String
