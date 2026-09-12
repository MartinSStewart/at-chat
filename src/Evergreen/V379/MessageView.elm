module Evergreen.V379.MessageView exposing (..)

import Date
import Duration
import Evergreen.V379.Coord
import Evergreen.V379.CssPixels
import Evergreen.V379.Discord
import Evergreen.V379.Emoji
import Evergreen.V379.Id
import Evergreen.V379.NonemptyDict
import Evergreen.V379.Point2d
import Evergreen.V379.RichText
import Evergreen.V379.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V379.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V379.NonemptyDict.NonemptyDict Int Evergreen.V379.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V379.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V379.Point2d.Point2d Evergreen.V379.CssPixels.CssPixels Evergreen.V379.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V379.Point2d.Point2d Evergreen.V379.CssPixels.CssPixels Evergreen.V379.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V379.Point2d.Point2d Evergreen.V379.CssPixels.CssPixels Evergreen.V379.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V379.Point2d.Point2d Evergreen.V379.CssPixels.CssPixels Evergreen.V379.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId)
