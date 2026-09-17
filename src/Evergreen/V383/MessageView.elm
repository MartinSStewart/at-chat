module Evergreen.V383.MessageView exposing (..)

import Date
import Duration
import Evergreen.V383.Coord
import Evergreen.V383.CssPixels
import Evergreen.V383.Discord
import Evergreen.V383.Emoji
import Evergreen.V383.Id
import Evergreen.V383.NonemptyDict
import Evergreen.V383.Point2d
import Evergreen.V383.RichText
import Evergreen.V383.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V383.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V383.NonemptyDict.NonemptyDict Int Evergreen.V383.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V383.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V383.Point2d.Point2d Evergreen.V383.CssPixels.CssPixels Evergreen.V383.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V383.Point2d.Point2d Evergreen.V383.CssPixels.CssPixels Evergreen.V383.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V383.Point2d.Point2d Evergreen.V383.CssPixels.CssPixels Evergreen.V383.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V383.Point2d.Point2d Evergreen.V383.CssPixels.CssPixels Evergreen.V383.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V383.Discord.Id Evergreen.V383.Discord.UserId)
