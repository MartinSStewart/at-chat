module Evergreen.V422.MessageView exposing (..)

import Date
import Duration
import Evergreen.V422.Coord
import Evergreen.V422.CssPixels
import Evergreen.V422.Discord
import Evergreen.V422.Emoji
import Evergreen.V422.FileStatus
import Evergreen.V422.Id
import Evergreen.V422.NonemptyDict
import Evergreen.V422.Point2d
import Evergreen.V422.RichText
import Evergreen.V422.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V422.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V422.NonemptyDict.NonemptyDict Int Evergreen.V422.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V422.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V422.Point2d.Point2d Evergreen.V422.CssPixels.CssPixels Evergreen.V422.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V422.Point2d.Point2d Evergreen.V422.CssPixels.CssPixels Evergreen.V422.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V422.Point2d.Point2d Evergreen.V422.CssPixels.CssPixels Evergreen.V422.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V422.Point2d.Point2d Evergreen.V422.CssPixels.CssPixels Evergreen.V422.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) Evergreen.V422.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) Evergreen.V422.Id.ThreadRoute
    | MessageView_PressedCopyCode String
    | MessageView_PressedPeerToPeerFile (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.FileStatus.PeerToPeerFile
