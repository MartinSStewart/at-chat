module Evergreen.V366.MessageView exposing (..)

import Date
import Duration
import Evergreen.V366.Coord
import Evergreen.V366.CssPixels
import Evergreen.V366.Discord
import Evergreen.V366.Emoji
import Evergreen.V366.Id
import Evergreen.V366.NonemptyDict
import Evergreen.V366.Point2d
import Evergreen.V366.RichText
import Evergreen.V366.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V366.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V366.NonemptyDict.NonemptyDict Int Evergreen.V366.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V366.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V366.Point2d.Point2d Evergreen.V366.CssPixels.CssPixels Evergreen.V366.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V366.Point2d.Point2d Evergreen.V366.CssPixels.CssPixels Evergreen.V366.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V366.Point2d.Point2d Evergreen.V366.CssPixels.CssPixels Evergreen.V366.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V366.Point2d.Point2d Evergreen.V366.CssPixels.CssPixels Evergreen.V366.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V366.Discord.Id Evergreen.V366.Discord.UserId)
