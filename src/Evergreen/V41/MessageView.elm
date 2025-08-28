module Evergreen.V41.MessageView exposing (..)

import Effect.Time
import Evergreen.V41.Coord
import Evergreen.V41.CssPixels
import Evergreen.V41.Emoji
import Evergreen.V41.Id
import Evergreen.V41.NonemptyDict
import Evergreen.V41.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Int
    | MessageView_MouseEnteredMessage (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | MessageView_MouseExitedMessage (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Evergreen.V41.NonemptyDict.NonemptyDict Int Evergreen.V41.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) Evergreen.V41.Emoji.Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowReactionEmojiSelector (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels)
    | MessageViewMsg_PressedEditMessage (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | MessageViewMsg_PressedReply (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId) (Evergreen.V41.Coord.Coord Evergreen.V41.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink (Evergreen.V41.Id.Id Evergreen.V41.Id.ChannelMessageId)
