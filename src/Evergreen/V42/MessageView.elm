module Evergreen.V42.MessageView exposing (..)

import Effect.Time
import Evergreen.V42.Coord
import Evergreen.V42.CssPixels
import Evergreen.V42.Emoji
import Evergreen.V42.Id
import Evergreen.V42.NonemptyDict
import Evergreen.V42.Touch


type MessageViewMsg
    = MessageView_PressedSpoiler (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Int
    | MessageView_MouseEnteredMessage (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | MessageView_MouseExitedMessage (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | MessageView_TouchStart Effect.Time.Posix Bool (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Evergreen.V42.NonemptyDict.NonemptyDict Int Evergreen.V42.Touch.Touch)
    | MessageView_AltPressedMessage Bool (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels)
    | MessageView_PressedReactionEmoji_Remove (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.Emoji.Emoji
    | MessageView_PressedReactionEmoji_Add (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) Evergreen.V42.Emoji.Emoji
    | MessageView_NoOp
    | MessageView_PressedReplyLink (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowReactionEmojiSelector (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels)
    | MessageViewMsg_PressedEditMessage (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | MessageViewMsg_PressedReply (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    | MessageViewMsg_PressedShowFullMenu Bool (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId) (Evergreen.V42.Coord.Coord Evergreen.V42.CssPixels.CssPixels)
    | MessageView_PressedViewThreadLink (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
