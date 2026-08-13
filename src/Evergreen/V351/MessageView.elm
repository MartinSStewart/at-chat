module Evergreen.V351.MessageView exposing (..)

import Date
import Duration
import Evergreen.V351.Coord
import Evergreen.V351.CssPixels
import Evergreen.V351.Discord
import Evergreen.V351.Emoji
import Evergreen.V351.Id
import Evergreen.V351.NonemptyDict
import Evergreen.V351.Point2d
import Evergreen.V351.RichText
import Evergreen.V351.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V351.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V351.NonemptyDict.NonemptyDict Int Evergreen.V351.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V351.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V351.Point2d.Point2d Evergreen.V351.CssPixels.CssPixels Evergreen.V351.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V351.Point2d.Point2d Evergreen.V351.CssPixels.CssPixels Evergreen.V351.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V351.Point2d.Point2d Evergreen.V351.CssPixels.CssPixels Evergreen.V351.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V351.Point2d.Point2d Evergreen.V351.CssPixels.CssPixels Evergreen.V351.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId)
