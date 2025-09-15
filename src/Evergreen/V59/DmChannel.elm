module Evergreen.V59.DmChannel exposing (..)

import Array
import Evergreen.V59.Discord.Id
import Evergreen.V59.Id
import Evergreen.V59.Message
import Evergreen.V59.OneToOne
import Evergreen.V59.Slack
import Evergreen.V59.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V59.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V59.Message.MessageState Evergreen.V59.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V59.VisibleMessages.VisibleMessages Evergreen.V59.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (LastTypedAt Evergreen.V59.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V59.Message.MessageState Evergreen.V59.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V59.VisibleMessages.VisibleMessages Evergreen.V59.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (LastTypedAt Evergreen.V59.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V59.Slack.Id Evergreen.V59.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V59.Message.Message Evergreen.V59.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (LastTypedAt Evergreen.V59.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V59.OneToOne.OneToOne ExternalMessageId (Evergreen.V59.Id.Id Evergreen.V59.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V59.Discord.Id.Id Evergreen.V59.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V59.Slack.Id Evergreen.V59.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V59.Message.Message Evergreen.V59.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) (LastTypedAt Evergreen.V59.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V59.OneToOne.OneToOne ExternalMessageId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V59.OneToOne.OneToOne ExternalChannelId (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelMessageId)
    }
