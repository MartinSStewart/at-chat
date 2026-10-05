module Evergreen.V398.MessageView exposing (..)

import Date
import Duration
import Evergreen.V398.Coord
import Evergreen.V398.CssPixels
import Evergreen.V398.Discord
import Evergreen.V398.Emoji
import Evergreen.V398.Id
import Evergreen.V398.NonemptyDict
import Evergreen.V398.Point2d
import Evergreen.V398.RichText
import Evergreen.V398.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V398.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V398.NonemptyDict.NonemptyDict Int Evergreen.V398.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V398.Coord.Coord Evergreen.V398.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V398.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V398.Point2d.Point2d Evergreen.V398.CssPixels.CssPixels Evergreen.V398.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V398.Point2d.Point2d Evergreen.V398.CssPixels.CssPixels Evergreen.V398.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V398.Point2d.Point2d Evergreen.V398.CssPixels.CssPixels Evergreen.V398.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V398.Point2d.Point2d Evergreen.V398.CssPixels.CssPixels Evergreen.V398.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) Evergreen.V398.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) Evergreen.V398.Id.ThreadRoute
    | MessageView_PressedCopyCode String
