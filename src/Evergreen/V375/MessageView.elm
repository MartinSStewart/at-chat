module Evergreen.V375.MessageView exposing (..)

import Date
import Duration
import Evergreen.V375.Coord
import Evergreen.V375.CssPixels
import Evergreen.V375.Discord
import Evergreen.V375.Emoji
import Evergreen.V375.Id
import Evergreen.V375.NonemptyDict
import Evergreen.V375.Point2d
import Evergreen.V375.RichText
import Evergreen.V375.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V375.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V375.NonemptyDict.NonemptyDict Int Evergreen.V375.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V375.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V375.Point2d.Point2d Evergreen.V375.CssPixels.CssPixels Evergreen.V375.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V375.Point2d.Point2d Evergreen.V375.CssPixels.CssPixels Evergreen.V375.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V375.Point2d.Point2d Evergreen.V375.CssPixels.CssPixels Evergreen.V375.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V375.Point2d.Point2d Evergreen.V375.CssPixels.CssPixels Evergreen.V375.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId)
