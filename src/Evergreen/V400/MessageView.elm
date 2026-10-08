module Evergreen.V400.MessageView exposing (..)

import Date
import Duration
import Evergreen.V400.Coord
import Evergreen.V400.CssPixels
import Evergreen.V400.Discord
import Evergreen.V400.Emoji
import Evergreen.V400.Id
import Evergreen.V400.NonemptyDict
import Evergreen.V400.Point2d
import Evergreen.V400.RichText
import Evergreen.V400.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V400.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V400.NonemptyDict.NonemptyDict Int Evergreen.V400.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V400.Coord.Coord Evergreen.V400.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V400.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V400.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V400.Coord.Coord Evergreen.V400.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V400.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V400.Point2d.Point2d Evergreen.V400.CssPixels.CssPixels Evergreen.V400.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V400.Point2d.Point2d Evergreen.V400.CssPixels.CssPixels Evergreen.V400.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V400.Point2d.Point2d Evergreen.V400.CssPixels.CssPixels Evergreen.V400.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V400.Point2d.Point2d Evergreen.V400.CssPixels.CssPixels Evergreen.V400.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId) Evergreen.V400.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) Evergreen.V400.Id.ThreadRoute
    | MessageView_PressedCopyCode String
