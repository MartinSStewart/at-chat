module Evergreen.V94.DmChannel exposing (..)

import Array
import Evergreen.V94.Discord.Id
import Evergreen.V94.Id
import Evergreen.V94.Message
import Evergreen.V94.OneToOne
import Evergreen.V94.Slack
import Evergreen.V94.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V94.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V94.Message.MessageState Evergreen.V94.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V94.VisibleMessages.VisibleMessages Evergreen.V94.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (LastTypedAt Evergreen.V94.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V94.Message.MessageState Evergreen.V94.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V94.VisibleMessages.VisibleMessages Evergreen.V94.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (LastTypedAt Evergreen.V94.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V94.Slack.Id Evergreen.V94.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V94.Message.Message Evergreen.V94.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (LastTypedAt Evergreen.V94.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V94.OneToOne.OneToOne ExternalMessageId (Evergreen.V94.Id.Id Evergreen.V94.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V94.Discord.Id.Id Evergreen.V94.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V94.Slack.Id Evergreen.V94.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V94.Message.Message Evergreen.V94.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) (LastTypedAt Evergreen.V94.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V94.OneToOne.OneToOne ExternalMessageId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V94.OneToOne.OneToOne ExternalChannelId (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId)
    }
