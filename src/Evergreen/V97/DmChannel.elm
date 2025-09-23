module Evergreen.V97.DmChannel exposing (..)

import Array
import Evergreen.V97.Discord.Id
import Evergreen.V97.Id
import Evergreen.V97.Message
import Evergreen.V97.OneToOne
import Evergreen.V97.Slack
import Evergreen.V97.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V97.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V97.Message.MessageState Evergreen.V97.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V97.VisibleMessages.VisibleMessages Evergreen.V97.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (LastTypedAt Evergreen.V97.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V97.Message.MessageState Evergreen.V97.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V97.VisibleMessages.VisibleMessages Evergreen.V97.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (LastTypedAt Evergreen.V97.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V97.Slack.Id Evergreen.V97.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V97.Message.Message Evergreen.V97.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (LastTypedAt Evergreen.V97.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V97.OneToOne.OneToOne ExternalMessageId (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V97.Discord.Id.Id Evergreen.V97.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V97.Slack.Id Evergreen.V97.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V97.Message.Message Evergreen.V97.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (LastTypedAt Evergreen.V97.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V97.OneToOne.OneToOne ExternalMessageId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V97.OneToOne.OneToOne ExternalChannelId (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)
    }
