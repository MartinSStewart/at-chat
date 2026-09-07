module Evergreen.V370.MessageView exposing (..)

import Date
import Duration
import Evergreen.V370.Coord
import Evergreen.V370.CssPixels
import Evergreen.V370.Discord
import Evergreen.V370.Emoji
import Evergreen.V370.Id
import Evergreen.V370.NonemptyDict
import Evergreen.V370.Point2d
import Evergreen.V370.RichText
import Evergreen.V370.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V370.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V370.NonemptyDict.NonemptyDict Int Evergreen.V370.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V370.Coord.Coord Evergreen.V370.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V370.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V370.Point2d.Point2d Evergreen.V370.CssPixels.CssPixels Evergreen.V370.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V370.Point2d.Point2d Evergreen.V370.CssPixels.CssPixels Evergreen.V370.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V370.Point2d.Point2d Evergreen.V370.CssPixels.CssPixels Evergreen.V370.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V370.Point2d.Point2d Evergreen.V370.CssPixels.CssPixels Evergreen.V370.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V370.Discord.Id Evergreen.V370.Discord.UserId)
