module Evergreen.V56.DmChannel exposing (..)

import Array
import Evergreen.V56.Discord.Id
import Evergreen.V56.Id
import Evergreen.V56.Message
import Evergreen.V56.OneToOne
import Evergreen.V56.Slack
import Evergreen.V56.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V56.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V56.Message.MessageState Evergreen.V56.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V56.VisibleMessages.VisibleMessages Evergreen.V56.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (LastTypedAt Evergreen.V56.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V56.Message.MessageState Evergreen.V56.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V56.VisibleMessages.VisibleMessages Evergreen.V56.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (LastTypedAt Evergreen.V56.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V56.Slack.Id Evergreen.V56.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V56.Message.Message Evergreen.V56.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (LastTypedAt Evergreen.V56.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V56.OneToOne.OneToOne ExternalMessageId (Evergreen.V56.Id.Id Evergreen.V56.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V56.Discord.Id.Id Evergreen.V56.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V56.Slack.Id Evergreen.V56.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V56.Message.Message Evergreen.V56.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (LastTypedAt Evergreen.V56.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V56.OneToOne.OneToOne ExternalMessageId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V56.OneToOne.OneToOne ExternalChannelId (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelMessageId)
    }
