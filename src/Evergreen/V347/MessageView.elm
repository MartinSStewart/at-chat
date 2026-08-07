module Evergreen.V347.MessageView exposing (..)

import Date
import Duration
import Evergreen.V347.Coord
import Evergreen.V347.CssPixels
import Evergreen.V347.Discord
import Evergreen.V347.Emoji
import Evergreen.V347.Id
import Evergreen.V347.NonemptyDict
import Evergreen.V347.Point2d
import Evergreen.V347.RichText
import Evergreen.V347.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V347.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V347.NonemptyDict.NonemptyDict Int Evergreen.V347.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V347.Coord.Coord Evergreen.V347.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V347.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V347.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V347.Coord.Coord Evergreen.V347.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V347.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V347.Point2d.Point2d Evergreen.V347.CssPixels.CssPixels Evergreen.V347.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V347.Point2d.Point2d Evergreen.V347.CssPixels.CssPixels Evergreen.V347.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V347.Point2d.Point2d Evergreen.V347.CssPixels.CssPixels Evergreen.V347.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V347.Point2d.Point2d Evergreen.V347.CssPixels.CssPixels Evergreen.V347.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId)
