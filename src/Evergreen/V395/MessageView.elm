module Evergreen.V395.MessageView exposing (..)

import Date
import Duration
import Evergreen.V395.Coord
import Evergreen.V395.CssPixels
import Evergreen.V395.Discord
import Evergreen.V395.Emoji
import Evergreen.V395.Id
import Evergreen.V395.NonemptyDict
import Evergreen.V395.Point2d
import Evergreen.V395.RichText
import Evergreen.V395.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V395.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V395.NonemptyDict.NonemptyDict Int Evergreen.V395.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V395.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V395.Point2d.Point2d Evergreen.V395.CssPixels.CssPixels Evergreen.V395.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V395.Point2d.Point2d Evergreen.V395.CssPixels.CssPixels Evergreen.V395.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V395.Point2d.Point2d Evergreen.V395.CssPixels.CssPixels Evergreen.V395.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V395.Point2d.Point2d Evergreen.V395.CssPixels.CssPixels Evergreen.V395.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId)
