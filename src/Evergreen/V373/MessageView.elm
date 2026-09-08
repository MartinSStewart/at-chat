module Evergreen.V373.MessageView exposing (..)

import Date
import Duration
import Evergreen.V373.Coord
import Evergreen.V373.CssPixels
import Evergreen.V373.Discord
import Evergreen.V373.Emoji
import Evergreen.V373.Id
import Evergreen.V373.NonemptyDict
import Evergreen.V373.Point2d
import Evergreen.V373.RichText
import Evergreen.V373.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V373.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V373.NonemptyDict.NonemptyDict Int Evergreen.V373.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V373.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V373.Point2d.Point2d Evergreen.V373.CssPixels.CssPixels Evergreen.V373.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V373.Point2d.Point2d Evergreen.V373.CssPixels.CssPixels Evergreen.V373.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V373.Point2d.Point2d Evergreen.V373.CssPixels.CssPixels Evergreen.V373.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V373.Point2d.Point2d Evergreen.V373.CssPixels.CssPixels Evergreen.V373.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId)
