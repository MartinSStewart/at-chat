module Evergreen.V408.MessageView exposing (..)

import Date
import Duration
import Evergreen.V408.Coord
import Evergreen.V408.CssPixels
import Evergreen.V408.Discord
import Evergreen.V408.Emoji
import Evergreen.V408.Id
import Evergreen.V408.NonemptyDict
import Evergreen.V408.Point2d
import Evergreen.V408.RichText
import Evergreen.V408.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V408.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V408.NonemptyDict.NonemptyDict Int Evergreen.V408.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V408.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V408.Point2d.Point2d Evergreen.V408.CssPixels.CssPixels Evergreen.V408.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V408.Point2d.Point2d Evergreen.V408.CssPixels.CssPixels Evergreen.V408.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V408.Point2d.Point2d Evergreen.V408.CssPixels.CssPixels Evergreen.V408.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V408.Point2d.Point2d Evergreen.V408.CssPixels.CssPixels Evergreen.V408.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) Evergreen.V408.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) Evergreen.V408.Id.ThreadRoute
    | MessageView_PressedCopyCode String
