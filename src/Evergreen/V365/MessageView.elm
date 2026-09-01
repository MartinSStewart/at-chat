module Evergreen.V365.MessageView exposing (..)

import Date
import Duration
import Evergreen.V365.Coord
import Evergreen.V365.CssPixels
import Evergreen.V365.Discord
import Evergreen.V365.Emoji
import Evergreen.V365.Id
import Evergreen.V365.NonemptyDict
import Evergreen.V365.Point2d
import Evergreen.V365.RichText
import Evergreen.V365.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V365.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V365.NonemptyDict.NonemptyDict Int Evergreen.V365.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V365.Coord.Coord Evergreen.V365.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V365.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V365.Point2d.Point2d Evergreen.V365.CssPixels.CssPixels Evergreen.V365.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V365.Point2d.Point2d Evergreen.V365.CssPixels.CssPixels Evergreen.V365.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V365.Point2d.Point2d Evergreen.V365.CssPixels.CssPixels Evergreen.V365.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V365.Point2d.Point2d Evergreen.V365.CssPixels.CssPixels Evergreen.V365.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId)
