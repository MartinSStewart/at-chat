module Evergreen.V367.MessageView exposing (..)

import Date
import Duration
import Evergreen.V367.Coord
import Evergreen.V367.CssPixels
import Evergreen.V367.Discord
import Evergreen.V367.Emoji
import Evergreen.V367.Id
import Evergreen.V367.NonemptyDict
import Evergreen.V367.Point2d
import Evergreen.V367.RichText
import Evergreen.V367.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V367.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V367.NonemptyDict.NonemptyDict Int Evergreen.V367.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V367.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V367.Point2d.Point2d Evergreen.V367.CssPixels.CssPixels Evergreen.V367.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V367.Point2d.Point2d Evergreen.V367.CssPixels.CssPixels Evergreen.V367.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V367.Point2d.Point2d Evergreen.V367.CssPixels.CssPixels Evergreen.V367.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V367.Point2d.Point2d Evergreen.V367.CssPixels.CssPixels Evergreen.V367.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId)
