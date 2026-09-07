module Evergreen.V372.MessageView exposing (..)

import Date
import Duration
import Evergreen.V372.Coord
import Evergreen.V372.CssPixels
import Evergreen.V372.Discord
import Evergreen.V372.Emoji
import Evergreen.V372.Id
import Evergreen.V372.NonemptyDict
import Evergreen.V372.Point2d
import Evergreen.V372.RichText
import Evergreen.V372.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V372.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V372.NonemptyDict.NonemptyDict Int Evergreen.V372.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V372.Coord.Coord Evergreen.V372.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V372.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V372.Point2d.Point2d Evergreen.V372.CssPixels.CssPixels Evergreen.V372.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V372.Point2d.Point2d Evergreen.V372.CssPixels.CssPixels Evergreen.V372.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V372.Point2d.Point2d Evergreen.V372.CssPixels.CssPixels Evergreen.V372.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V372.Point2d.Point2d Evergreen.V372.CssPixels.CssPixels Evergreen.V372.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId)
