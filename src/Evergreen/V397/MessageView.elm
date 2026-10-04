module Evergreen.V397.MessageView exposing (..)

import Date
import Duration
import Evergreen.V397.Coord
import Evergreen.V397.CssPixels
import Evergreen.V397.Discord
import Evergreen.V397.Emoji
import Evergreen.V397.Id
import Evergreen.V397.NonemptyDict
import Evergreen.V397.Point2d
import Evergreen.V397.RichText
import Evergreen.V397.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V397.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V397.NonemptyDict.NonemptyDict Int Evergreen.V397.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V397.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V397.Point2d.Point2d Evergreen.V397.CssPixels.CssPixels Evergreen.V397.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V397.Point2d.Point2d Evergreen.V397.CssPixels.CssPixels Evergreen.V397.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V397.Point2d.Point2d Evergreen.V397.CssPixels.CssPixels Evergreen.V397.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V397.Point2d.Point2d Evergreen.V397.CssPixels.CssPixels Evergreen.V397.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) Evergreen.V397.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) Evergreen.V397.Id.ThreadRoute
