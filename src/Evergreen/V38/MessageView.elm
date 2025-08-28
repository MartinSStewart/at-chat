module Evergreen.V38.MessageView exposing (..)

import Effect.Time
import Evergreen.V38.Coord
import Evergreen.V38.CssPixels
import Evergreen.V38.Emoji
import Evergreen.V38.Id
import Evergreen.V38.NonemptyDict
import Evergreen.V38.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Int
    | MessageView_MouseEnteredMessage (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | MessageView_MouseExitedMessage (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Evergreen.V38.NonemptyDict.NonemptyDict Int Evergreen.V38.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) Evergreen.V38.Emoji.Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowReactionEmojiSelector (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels)
    | MessageViewMsg_PressedEditMessage (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | MessageViewMsg_PressedReply (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId) (Evergreen.V38.Coord.Coord Evergreen.V38.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
