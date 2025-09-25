module Evergreen.V104.DmChannel exposing (..)

import Array
import Evergreen.V104.Discord.Id
import Evergreen.V104.Id
import Evergreen.V104.Message
import Evergreen.V104.OneToOne
import Evergreen.V104.Slack
import Evergreen.V104.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V104.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V104.Message.MessageState Evergreen.V104.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V104.VisibleMessages.VisibleMessages Evergreen.V104.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (LastTypedAt Evergreen.V104.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V104.Message.MessageState Evergreen.V104.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V104.VisibleMessages.VisibleMessages Evergreen.V104.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (LastTypedAt Evergreen.V104.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V104.Slack.Id Evergreen.V104.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V104.Message.Message Evergreen.V104.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (LastTypedAt Evergreen.V104.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V104.OneToOne.OneToOne ExternalMessageId (Evergreen.V104.Id.Id Evergreen.V104.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V104.Discord.Id.Id Evergreen.V104.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V104.Slack.Id Evergreen.V104.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V104.Message.Message Evergreen.V104.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (LastTypedAt Evergreen.V104.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V104.OneToOne.OneToOne ExternalMessageId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V104.OneToOne.OneToOne ExternalChannelId (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId)
    }
