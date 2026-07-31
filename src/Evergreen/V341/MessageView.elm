module Evergreen.V341.MessageView exposing (..)

import Date
import Duration
import Evergreen.V341.Coord
import Evergreen.V341.CssPixels
import Evergreen.V341.Discord
import Evergreen.V341.Emoji
import Evergreen.V341.Id
import Evergreen.V341.NonemptyDict
import Evergreen.V341.Point2d
import Evergreen.V341.RichText
import Evergreen.V341.Touch
import Url


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url.Url
    | MessageView_PressedImage Evergreen.V341.RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration.Duration Bool (Maybe String) (Maybe String) (Evergreen.V341.NonemptyDict.NonemptyDict Int Evergreen.V341.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V341.Coord.Coord Evergreen.V341.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji Evergreen.V341.Emoji.EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Evergreen.V341.Point2d.Point2d Evergreen.V341.CssPixels.CssPixels Evergreen.V341.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Evergreen.V341.Point2d.Point2d Evergreen.V341.CssPixels.CssPixels Evergreen.V341.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date.Date (Evergreen.V341.Point2d.Point2d Evergreen.V341.CssPixels.CssPixels Evergreen.V341.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Evergreen.V341.Point2d.Point2d Evergreen.V341.CssPixels.CssPixels Evergreen.V341.Touch.ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    | MessageView_PressedDiscordUserIconButton (Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId)
