module Evergreen.V421.MessageView exposing (..)

import Date
import Duration
import Evergreen.V421.Coord
import Evergreen.V421.CssPixels
import Evergreen.V421.Discord
import Evergreen.V421.Emoji
import Evergreen.V421.FileStatus
import Evergreen.V421.Id
import Evergreen.V421.NonemptyDict
import Evergreen.V421.Point2d
import Evergreen.V421.RichText
import Evergreen.V421.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V421.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V421.NonemptyDict.NonemptyDict Int Evergreen.V421.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V421.Coord.Coord Evergreen.V421.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V421.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V421.Point2d.Point2d Evergreen.V421.CssPixels.CssPixels Evergreen.V421.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V421.Point2d.Point2d Evergreen.V421.CssPixels.CssPixels Evergreen.V421.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V421.Point2d.Point2d Evergreen.V421.CssPixels.CssPixels Evergreen.V421.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V421.Point2d.Point2d Evergreen.V421.CssPixels.CssPixels Evergreen.V421.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) Evergreen.V421.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) Evergreen.V421.Id.ThreadRoute
    | MessageView_PressedCopyCode String
    | MessageView_PressedPeerToPeerFile (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.FileStatus.PeerToPeerFile
