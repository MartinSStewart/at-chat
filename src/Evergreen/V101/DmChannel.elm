module Evergreen.V101.DmChannel exposing (..)

import Array
import Evergreen.V101.Discord.Id
import Evergreen.V101.Id
import Evergreen.V101.Message
import Evergreen.V101.OneToOne
import Evergreen.V101.Slack
import Evergreen.V101.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V101.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V101.Message.MessageState Evergreen.V101.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V101.VisibleMessages.VisibleMessages Evergreen.V101.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (LastTypedAt Evergreen.V101.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V101.Message.MessageState Evergreen.V101.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V101.VisibleMessages.VisibleMessages Evergreen.V101.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (LastTypedAt Evergreen.V101.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V101.Slack.Id Evergreen.V101.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V101.Message.Message Evergreen.V101.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (LastTypedAt Evergreen.V101.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V101.OneToOne.OneToOne ExternalMessageId (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V101.Discord.Id.Id Evergreen.V101.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V101.Slack.Id Evergreen.V101.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V101.Message.Message Evergreen.V101.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (LastTypedAt Evergreen.V101.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V101.OneToOne.OneToOne ExternalMessageId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V101.OneToOne.OneToOne ExternalChannelId (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)
    }
