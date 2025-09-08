module Evergreen.V52.DmChannel exposing (..)

import Array
import Evergreen.V52.Discord.Id
import Evergreen.V52.Id
import Evergreen.V52.Message
import Evergreen.V52.OneToOne
import Evergreen.V52.Slack
import Evergreen.V52.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V52.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V52.Message.MessageState Evergreen.V52.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V52.VisibleMessages.VisibleMessages Evergreen.V52.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (LastTypedAt Evergreen.V52.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V52.Message.MessageState Evergreen.V52.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V52.VisibleMessages.VisibleMessages Evergreen.V52.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (LastTypedAt Evergreen.V52.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V52.Slack.Id Evergreen.V52.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V52.Message.Message Evergreen.V52.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (LastTypedAt Evergreen.V52.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V52.OneToOne.OneToOne ExternalMessageId (Evergreen.V52.Id.Id Evergreen.V52.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V52.Discord.Id.Id Evergreen.V52.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V52.Slack.Id Evergreen.V52.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V52.Message.Message Evergreen.V52.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (LastTypedAt Evergreen.V52.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V52.OneToOne.OneToOne ExternalMessageId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V52.OneToOne.OneToOne ExternalChannelId (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelMessageId)
    }
