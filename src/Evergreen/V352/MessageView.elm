module Evergreen.V352.MessageView exposing (..)

import Date
import Duration
import Evergreen.V352.Coord
import Evergreen.V352.CssPixels
import Evergreen.V352.Discord
import Evergreen.V352.Emoji
import Evergreen.V352.Id
import Evergreen.V352.NonemptyDict
import Evergreen.V352.Point2d
import Evergreen.V352.RichText
import Evergreen.V352.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V352.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V352.NonemptyDict.NonemptyDict Int Evergreen.V352.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V352.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V352.Point2d.Point2d Evergreen.V352.CssPixels.CssPixels Evergreen.V352.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V352.Point2d.Point2d Evergreen.V352.CssPixels.CssPixels Evergreen.V352.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V352.Point2d.Point2d Evergreen.V352.CssPixels.CssPixels Evergreen.V352.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V352.Point2d.Point2d Evergreen.V352.CssPixels.CssPixels Evergreen.V352.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V352.Id.Id Evergreen.V352.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId)
