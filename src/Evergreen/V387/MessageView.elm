module Evergreen.V387.MessageView exposing (..)

import Date
import Duration
import Evergreen.V387.Coord
import Evergreen.V387.CssPixels
import Evergreen.V387.Discord
import Evergreen.V387.Emoji
import Evergreen.V387.Id
import Evergreen.V387.NonemptyDict
import Evergreen.V387.Point2d
import Evergreen.V387.RichText
import Evergreen.V387.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V387.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V387.NonemptyDict.NonemptyDict Int Evergreen.V387.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V387.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V387.Point2d.Point2d Evergreen.V387.CssPixels.CssPixels Evergreen.V387.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V387.Point2d.Point2d Evergreen.V387.CssPixels.CssPixels Evergreen.V387.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V387.Point2d.Point2d Evergreen.V387.CssPixels.CssPixels Evergreen.V387.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V387.Point2d.Point2d Evergreen.V387.CssPixels.CssPixels Evergreen.V387.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId)
