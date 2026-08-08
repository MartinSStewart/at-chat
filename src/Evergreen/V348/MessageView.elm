module Evergreen.V348.MessageView exposing (..)

import Date
import Duration
import Evergreen.V348.Coord
import Evergreen.V348.CssPixels
import Evergreen.V348.Discord
import Evergreen.V348.Emoji
import Evergreen.V348.Id
import Evergreen.V348.NonemptyDict
import Evergreen.V348.Point2d
import Evergreen.V348.RichText
import Evergreen.V348.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V348.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V348.NonemptyDict.NonemptyDict Int Evergreen.V348.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V348.Coord.Coord Evergreen.V348.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V348.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V348.Point2d.Point2d Evergreen.V348.CssPixels.CssPixels Evergreen.V348.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V348.Point2d.Point2d Evergreen.V348.CssPixels.CssPixels Evergreen.V348.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V348.Point2d.Point2d Evergreen.V348.CssPixels.CssPixels Evergreen.V348.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V348.Point2d.Point2d Evergreen.V348.CssPixels.CssPixels Evergreen.V348.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId)
