module Evergreen.V53.DmChannel exposing (..)

import Array
import Evergreen.V53.Discord.Id
import Evergreen.V53.Id
import Evergreen.V53.Message
import Evergreen.V53.OneToOne
import Evergreen.V53.Slack
import Evergreen.V53.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V53.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V53.Message.MessageState Evergreen.V53.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V53.VisibleMessages.VisibleMessages Evergreen.V53.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (LastTypedAt Evergreen.V53.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V53.Message.MessageState Evergreen.V53.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V53.VisibleMessages.VisibleMessages Evergreen.V53.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (LastTypedAt Evergreen.V53.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V53.Slack.Id Evergreen.V53.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V53.Message.Message Evergreen.V53.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (LastTypedAt Evergreen.V53.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V53.OneToOne.OneToOne ExternalMessageId (Evergreen.V53.Id.Id Evergreen.V53.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V53.Discord.Id.Id Evergreen.V53.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V53.Slack.Id Evergreen.V53.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V53.Message.Message Evergreen.V53.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (LastTypedAt Evergreen.V53.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V53.OneToOne.OneToOne ExternalMessageId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V53.OneToOne.OneToOne ExternalChannelId (Evergreen.V53.Id.Id Evergreen.V53.Id.ChannelMessageId)
    }
