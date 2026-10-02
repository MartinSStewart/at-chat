module Evergreen.V396.MessageView exposing (..)

import Date
import Duration
import Evergreen.V396.Coord
import Evergreen.V396.CssPixels
import Evergreen.V396.Discord
import Evergreen.V396.Emoji
import Evergreen.V396.Id
import Evergreen.V396.NonemptyDict
import Evergreen.V396.Point2d
import Evergreen.V396.RichText
import Evergreen.V396.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V396.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V396.NonemptyDict.NonemptyDict Int Evergreen.V396.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V396.Coord.Coord Evergreen.V396.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V396.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V396.Point2d.Point2d Evergreen.V396.CssPixels.CssPixels Evergreen.V396.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V396.Point2d.Point2d Evergreen.V396.CssPixels.CssPixels Evergreen.V396.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V396.Point2d.Point2d Evergreen.V396.CssPixels.CssPixels Evergreen.V396.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V396.Point2d.Point2d Evergreen.V396.CssPixels.CssPixels Evergreen.V396.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId)
