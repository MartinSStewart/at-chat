module Evergreen.V388.MessageView exposing (..)

import Date
import Duration
import Evergreen.V388.Coord
import Evergreen.V388.CssPixels
import Evergreen.V388.Discord
import Evergreen.V388.Emoji
import Evergreen.V388.Id
import Evergreen.V388.NonemptyDict
import Evergreen.V388.Point2d
import Evergreen.V388.RichText
import Evergreen.V388.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V388.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V388.NonemptyDict.NonemptyDict Int Evergreen.V388.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V388.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V388.Point2d.Point2d Evergreen.V388.CssPixels.CssPixels Evergreen.V388.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V388.Point2d.Point2d Evergreen.V388.CssPixels.CssPixels Evergreen.V388.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V388.Point2d.Point2d Evergreen.V388.CssPixels.CssPixels Evergreen.V388.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V388.Point2d.Point2d Evergreen.V388.CssPixels.CssPixels Evergreen.V388.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V388.Discord.Id Evergreen.V388.Discord.UserId)
