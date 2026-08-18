module Evergreen.V357.MessageView exposing (..)

import Date
import Duration
import Evergreen.V357.Coord
import Evergreen.V357.CssPixels
import Evergreen.V357.Discord
import Evergreen.V357.Emoji
import Evergreen.V357.Id
import Evergreen.V357.NonemptyDict
import Evergreen.V357.Point2d
import Evergreen.V357.RichText
import Evergreen.V357.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V357.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V357.NonemptyDict.NonemptyDict Int Evergreen.V357.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V357.Coord.Coord Evergreen.V357.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V357.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V357.Point2d.Point2d Evergreen.V357.CssPixels.CssPixels Evergreen.V357.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V357.Point2d.Point2d Evergreen.V357.CssPixels.CssPixels Evergreen.V357.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V357.Point2d.Point2d Evergreen.V357.CssPixels.CssPixels Evergreen.V357.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V357.Point2d.Point2d Evergreen.V357.CssPixels.CssPixels Evergreen.V357.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId)
