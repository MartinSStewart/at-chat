module Evergreen.V364.MessageView exposing (..)

import Date
import Duration
import Evergreen.V364.Coord
import Evergreen.V364.CssPixels
import Evergreen.V364.Discord
import Evergreen.V364.Emoji
import Evergreen.V364.Id
import Evergreen.V364.NonemptyDict
import Evergreen.V364.Point2d
import Evergreen.V364.RichText
import Evergreen.V364.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V364.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V364.NonemptyDict.NonemptyDict Int Evergreen.V364.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V364.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V364.Point2d.Point2d Evergreen.V364.CssPixels.CssPixels Evergreen.V364.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V364.Point2d.Point2d Evergreen.V364.CssPixels.CssPixels Evergreen.V364.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V364.Point2d.Point2d Evergreen.V364.CssPixels.CssPixels Evergreen.V364.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V364.Point2d.Point2d Evergreen.V364.CssPixels.CssPixels Evergreen.V364.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId)
