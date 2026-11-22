module Evergreen.V423.MessageView exposing (..)

import Date
import Duration
import Evergreen.V423.Coord
import Evergreen.V423.CssPixels
import Evergreen.V423.Discord
import Evergreen.V423.Emoji
import Evergreen.V423.FileStatus
import Evergreen.V423.Id
import Evergreen.V423.NonemptyDict
import Evergreen.V423.Point2d
import Evergreen.V423.RichText
import Evergreen.V423.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V423.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V423.NonemptyDict.NonemptyDict Int Evergreen.V423.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V423.Coord.Coord Evergreen.V423.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V423.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V423.Point2d.Point2d Evergreen.V423.CssPixels.CssPixels Evergreen.V423.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V423.Point2d.Point2d Evergreen.V423.CssPixels.CssPixels Evergreen.V423.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V423.Point2d.Point2d Evergreen.V423.CssPixels.CssPixels Evergreen.V423.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V423.Point2d.Point2d Evergreen.V423.CssPixels.CssPixels Evergreen.V423.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) Evergreen.V423.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) Evergreen.V423.Id.ThreadRoute
    | MessageView_PressedCopyCode String
    | MessageView_PressedPeerToPeerFile (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.FileStatus.PeerToPeerFile
