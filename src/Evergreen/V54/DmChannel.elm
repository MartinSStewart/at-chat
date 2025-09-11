module Evergreen.V54.DmChannel exposing (..)

import Array
import Evergreen.V54.Discord.Id
import Evergreen.V54.Id
import Evergreen.V54.Message
import Evergreen.V54.OneToOne
import Evergreen.V54.Slack
import Evergreen.V54.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V54.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V54.Message.MessageState Evergreen.V54.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V54.VisibleMessages.VisibleMessages Evergreen.V54.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (LastTypedAt Evergreen.V54.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V54.Message.MessageState Evergreen.V54.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V54.VisibleMessages.VisibleMessages Evergreen.V54.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (LastTypedAt Evergreen.V54.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V54.Slack.Id Evergreen.V54.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V54.Message.Message Evergreen.V54.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (LastTypedAt Evergreen.V54.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V54.OneToOne.OneToOne ExternalMessageId (Evergreen.V54.Id.Id Evergreen.V54.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V54.Discord.Id.Id Evergreen.V54.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V54.Slack.Id Evergreen.V54.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V54.Message.Message Evergreen.V54.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (LastTypedAt Evergreen.V54.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V54.OneToOne.OneToOne ExternalMessageId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V54.OneToOne.OneToOne ExternalChannelId (Evergreen.V54.Id.Id Evergreen.V54.Id.ChannelMessageId)
    }
