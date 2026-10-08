module Evergreen.V401.MessageView exposing (..)

import Date
import Duration
import Evergreen.V401.Coord
import Evergreen.V401.CssPixels
import Evergreen.V401.Discord
import Evergreen.V401.Emoji
import Evergreen.V401.Id
import Evergreen.V401.NonemptyDict
import Evergreen.V401.Point2d
import Evergreen.V401.RichText
import Evergreen.V401.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V401.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V401.NonemptyDict.NonemptyDict Int Evergreen.V401.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V401.Coord.Coord Evergreen.V401.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V401.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V401.Point2d.Point2d Evergreen.V401.CssPixels.CssPixels Evergreen.V401.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V401.Point2d.Point2d Evergreen.V401.CssPixels.CssPixels Evergreen.V401.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V401.Point2d.Point2d Evergreen.V401.CssPixels.CssPixels Evergreen.V401.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V401.Point2d.Point2d Evergreen.V401.CssPixels.CssPixels Evergreen.V401.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) Evergreen.V401.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) Evergreen.V401.Id.ThreadRoute
    | MessageView_PressedCopyCode String
