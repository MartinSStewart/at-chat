module Evergreen.V346.MessageView exposing (..)

import Date
import Duration
import Evergreen.V346.Coord
import Evergreen.V346.CssPixels
import Evergreen.V346.Discord
import Evergreen.V346.Emoji
import Evergreen.V346.Id
import Evergreen.V346.NonemptyDict
import Evergreen.V346.Point2d
import Evergreen.V346.RichText
import Evergreen.V346.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V346.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V346.NonemptyDict.NonemptyDict Int Evergreen.V346.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V346.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V346.Point2d.Point2d Evergreen.V346.CssPixels.CssPixels Evergreen.V346.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V346.Point2d.Point2d Evergreen.V346.CssPixels.CssPixels Evergreen.V346.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V346.Point2d.Point2d Evergreen.V346.CssPixels.CssPixels Evergreen.V346.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V346.Point2d.Point2d Evergreen.V346.CssPixels.CssPixels Evergreen.V346.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId)
