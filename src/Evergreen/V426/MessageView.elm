module Evergreen.V426.MessageView exposing (..)

import Date
import Duration
import Evergreen.V426.Coord
import Evergreen.V426.CssPixels
import Evergreen.V426.Discord
import Evergreen.V426.Emoji
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import Evergreen.V426.NonemptyDict
import Evergreen.V426.Point2d
import Evergreen.V426.RichText
import Evergreen.V426.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V426.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V426.NonemptyDict.NonemptyDict Int Evergreen.V426.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Maybe Int) (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V426.Coord.Coord Evergreen.V426.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V426.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V426.Point2d.Point2d Evergreen.V426.CssPixels.CssPixels Evergreen.V426.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V426.Point2d.Point2d Evergreen.V426.CssPixels.CssPixels Evergreen.V426.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V426.Point2d.Point2d Evergreen.V426.CssPixels.CssPixels Evergreen.V426.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V426.Point2d.Point2d Evergreen.V426.CssPixels.CssPixels Evergreen.V426.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId)
    | MessageView_PressedChannelMention (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) Evergreen.V426.Id.ThreadRoute
    | MessageView_PressedDiscordChannelMention (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) Evergreen.V426.Id.ThreadRoute
    | MessageView_PressedCopyCode String
    | MessageView_PressedPeerToPeerFile (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.FileStatus.PeerToPeerFile
