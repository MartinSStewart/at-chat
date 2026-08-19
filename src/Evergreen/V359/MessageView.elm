module Evergreen.V359.MessageView exposing (..)

import Date
import Duration
import Evergreen.V359.Coord
import Evergreen.V359.CssPixels
import Evergreen.V359.Discord
import Evergreen.V359.Emoji
import Evergreen.V359.Id
import Evergreen.V359.NonemptyDict
import Evergreen.V359.Point2d
import Evergreen.V359.RichText
import Evergreen.V359.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V359.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V359.NonemptyDict.NonemptyDict Int Evergreen.V359.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V359.Coord.Coord Evergreen.V359.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V359.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V359.Point2d.Point2d Evergreen.V359.CssPixels.CssPixels Evergreen.V359.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V359.Point2d.Point2d Evergreen.V359.CssPixels.CssPixels Evergreen.V359.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V359.Point2d.Point2d Evergreen.V359.CssPixels.CssPixels Evergreen.V359.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V359.Point2d.Point2d Evergreen.V359.CssPixels.CssPixels Evergreen.V359.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId)
