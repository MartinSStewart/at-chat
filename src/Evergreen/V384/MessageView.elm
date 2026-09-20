module Evergreen.V384.MessageView exposing (..)

import Date
import Duration
import Evergreen.V384.Coord
import Evergreen.V384.CssPixels
import Evergreen.V384.Discord
import Evergreen.V384.Emoji
import Evergreen.V384.Id
import Evergreen.V384.NonemptyDict
import Evergreen.V384.Point2d
import Evergreen.V384.RichText
import Evergreen.V384.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V384.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V384.NonemptyDict.NonemptyDict Int Evergreen.V384.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V384.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V384.Point2d.Point2d Evergreen.V384.CssPixels.CssPixels Evergreen.V384.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V384.Point2d.Point2d Evergreen.V384.CssPixels.CssPixels Evergreen.V384.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V384.Point2d.Point2d Evergreen.V384.CssPixels.CssPixels Evergreen.V384.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V384.Point2d.Point2d Evergreen.V384.CssPixels.CssPixels Evergreen.V384.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId)
