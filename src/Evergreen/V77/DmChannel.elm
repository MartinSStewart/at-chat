module Evergreen.V77.DmChannel exposing (..)

import Array
import Evergreen.V77.Discord.Id
import Evergreen.V77.Id
import Evergreen.V77.Message
import Evergreen.V77.OneToOne
import Evergreen.V77.Slack
import Evergreen.V77.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V77.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V77.Message.MessageState Evergreen.V77.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V77.VisibleMessages.VisibleMessages Evergreen.V77.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (LastTypedAt Evergreen.V77.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V77.Message.MessageState Evergreen.V77.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V77.VisibleMessages.VisibleMessages Evergreen.V77.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (LastTypedAt Evergreen.V77.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V77.Slack.Id Evergreen.V77.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V77.Message.Message Evergreen.V77.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (LastTypedAt Evergreen.V77.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V77.OneToOne.OneToOne ExternalMessageId (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V77.Discord.Id.Id Evergreen.V77.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V77.Slack.Id Evergreen.V77.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V77.Message.Message Evergreen.V77.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) (LastTypedAt Evergreen.V77.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V77.OneToOne.OneToOne ExternalMessageId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V77.OneToOne.OneToOne ExternalChannelId (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)
    }
