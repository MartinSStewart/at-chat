module Evergreen.V363.MessageView exposing (..)

import Date
import Duration
import Evergreen.V363.Coord
import Evergreen.V363.CssPixels
import Evergreen.V363.Discord
import Evergreen.V363.Emoji
import Evergreen.V363.Id
import Evergreen.V363.NonemptyDict
import Evergreen.V363.Point2d
import Evergreen.V363.RichText
import Evergreen.V363.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V363.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V363.NonemptyDict.NonemptyDict Int Evergreen.V363.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V363.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V363.Point2d.Point2d Evergreen.V363.CssPixels.CssPixels Evergreen.V363.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V363.Point2d.Point2d Evergreen.V363.CssPixels.CssPixels Evergreen.V363.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V363.Point2d.Point2d Evergreen.V363.CssPixels.CssPixels Evergreen.V363.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V363.Point2d.Point2d Evergreen.V363.CssPixels.CssPixels Evergreen.V363.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId)
