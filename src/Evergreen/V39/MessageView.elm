module Evergreen.V39.MessageView exposing (..)

import Effect.Time
import Evergreen.V39.Coord
import Evergreen.V39.CssPixels
import Evergreen.V39.Emoji
import Evergreen.V39.Id
import Evergreen.V39.NonemptyDict
import Evergreen.V39.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Int
    | MessageView_MouseEnteredMessage (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | MessageView_MouseExitedMessage (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Evergreen.V39.NonemptyDict.NonemptyDict Int Evergreen.V39.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) Evergreen.V39.Emoji.Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowReactionEmojiSelector (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels)
    | MessageViewMsg_PressedEditMessage (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | MessageViewMsg_PressedReply (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId) (Evergreen.V39.Coord.Coord Evergreen.V39.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
