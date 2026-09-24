module Evergreen.V385.MessageView exposing (..)

import Date
import Duration
import Evergreen.V385.Coord
import Evergreen.V385.CssPixels
import Evergreen.V385.Discord
import Evergreen.V385.Emoji
import Evergreen.V385.Id
import Evergreen.V385.NonemptyDict
import Evergreen.V385.Point2d
import Evergreen.V385.RichText
import Evergreen.V385.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V385.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V385.NonemptyDict.NonemptyDict Int Evergreen.V385.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V385.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V385.Point2d.Point2d Evergreen.V385.CssPixels.CssPixels Evergreen.V385.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V385.Point2d.Point2d Evergreen.V385.CssPixels.CssPixels Evergreen.V385.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V385.Point2d.Point2d Evergreen.V385.CssPixels.CssPixels Evergreen.V385.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V385.Point2d.Point2d Evergreen.V385.CssPixels.CssPixels Evergreen.V385.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId)
