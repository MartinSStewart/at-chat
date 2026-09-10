module Evergreen.V376.MessageView exposing (..)

import Date
import Duration
import Evergreen.V376.Coord
import Evergreen.V376.CssPixels
import Evergreen.V376.Discord
import Evergreen.V376.Emoji
import Evergreen.V376.Id
import Evergreen.V376.NonemptyDict
import Evergreen.V376.Point2d
import Evergreen.V376.RichText
import Evergreen.V376.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V376.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V376.NonemptyDict.NonemptyDict Int Evergreen.V376.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V376.Coord.Coord Evergreen.V376.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V376.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V376.Point2d.Point2d Evergreen.V376.CssPixels.CssPixels Evergreen.V376.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V376.Point2d.Point2d Evergreen.V376.CssPixels.CssPixels Evergreen.V376.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V376.Point2d.Point2d Evergreen.V376.CssPixels.CssPixels Evergreen.V376.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V376.Point2d.Point2d Evergreen.V376.CssPixels.CssPixels Evergreen.V376.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId)
