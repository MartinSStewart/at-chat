module Evergreen.V349.MessageView exposing (..)

import Date
import Duration
import Evergreen.V349.Coord
import Evergreen.V349.CssPixels
import Evergreen.V349.Discord
import Evergreen.V349.Emoji
import Evergreen.V349.Id
import Evergreen.V349.NonemptyDict
import Evergreen.V349.Point2d
import Evergreen.V349.RichText
import Evergreen.V349.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V349.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V349.NonemptyDict.NonemptyDict Int Evergreen.V349.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V349.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V349.Point2d.Point2d Evergreen.V349.CssPixels.CssPixels Evergreen.V349.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V349.Point2d.Point2d Evergreen.V349.CssPixels.CssPixels Evergreen.V349.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V349.Point2d.Point2d Evergreen.V349.CssPixels.CssPixels Evergreen.V349.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V349.Point2d.Point2d Evergreen.V349.CssPixels.CssPixels Evergreen.V349.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId)
