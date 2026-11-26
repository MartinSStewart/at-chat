module Evergreen.V425.MessageView exposing (..)

import Date
import Duration
import Evergreen.V425.Coord
import Evergreen.V425.CssPixels
import Evergreen.V425.Discord
import Evergreen.V425.Emoji
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import Evergreen.V425.NonemptyDict
import Evergreen.V425.Point2d
import Evergreen.V425.RichText
import Evergreen.V425.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V425.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V425.NonemptyDict.NonemptyDict Int Evergreen.V425.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V425.Coord.Coord Evergreen.V425.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V425.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V425.Point2d.Point2d Evergreen.V425.CssPixels.CssPixels Evergreen.V425.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V425.Point2d.Point2d Evergreen.V425.CssPixels.CssPixels Evergreen.V425.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V425.Point2d.Point2d Evergreen.V425.CssPixels.CssPixels Evergreen.V425.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V425.Point2d.Point2d Evergreen.V425.CssPixels.CssPixels Evergreen.V425.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) Evergreen.V425.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) Evergreen.V425.Id.ThreadRoute
    | MessageView_PressedCopyCode String
    | MessageView_PressedPeerToPeerFile (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.FileStatus.PeerToPeerFile
