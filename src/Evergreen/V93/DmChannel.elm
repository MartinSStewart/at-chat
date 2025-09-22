module Evergreen.V93.DmChannel exposing (..)

import Array
import Evergreen.V93.Discord.Id
import Evergreen.V93.Id
import Evergreen.V93.Message
import Evergreen.V93.OneToOne
import Evergreen.V93.Slack
import Evergreen.V93.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V93.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V93.Message.MessageState Evergreen.V93.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V93.VisibleMessages.VisibleMessages Evergreen.V93.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (LastTypedAt Evergreen.V93.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V93.Message.MessageState Evergreen.V93.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V93.VisibleMessages.VisibleMessages Evergreen.V93.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (LastTypedAt Evergreen.V93.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V93.Slack.Id Evergreen.V93.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V93.Message.Message Evergreen.V93.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (LastTypedAt Evergreen.V93.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V93.OneToOne.OneToOne ExternalMessageId (Evergreen.V93.Id.Id Evergreen.V93.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V93.Discord.Id.Id Evergreen.V93.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V93.Slack.Id Evergreen.V93.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V93.Message.Message Evergreen.V93.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) (LastTypedAt Evergreen.V93.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V93.OneToOne.OneToOne ExternalMessageId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V93.OneToOne.OneToOne ExternalChannelId (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId)
    }
