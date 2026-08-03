module Evergreen.V344.MessageView exposing (..)

import Date
import Duration
import Evergreen.V344.Coord
import Evergreen.V344.CssPixels
import Evergreen.V344.Discord
import Evergreen.V344.Emoji
import Evergreen.V344.Id
import Evergreen.V344.NonemptyDict
import Evergreen.V344.Point2d
import Evergreen.V344.RichText
import Evergreen.V344.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V344.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V344.NonemptyDict.NonemptyDict Int Evergreen.V344.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V344.Coord.Coord Evergreen.V344.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V344.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V344.Point2d.Point2d Evergreen.V344.CssPixels.CssPixels Evergreen.V344.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V344.Point2d.Point2d Evergreen.V344.CssPixels.CssPixels Evergreen.V344.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V344.Point2d.Point2d Evergreen.V344.CssPixels.CssPixels Evergreen.V344.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V344.Point2d.Point2d Evergreen.V344.CssPixels.CssPixels Evergreen.V344.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId)
