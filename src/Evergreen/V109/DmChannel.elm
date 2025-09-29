module Evergreen.V109.DmChannel exposing (..)

import Array
import Evergreen.V109.Discord.Id
import Evergreen.V109.Id
import Evergreen.V109.Message
import Evergreen.V109.OneToOne
import Evergreen.V109.Slack
import Evergreen.V109.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V109.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V109.Message.MessageState Evergreen.V109.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V109.VisibleMessages.VisibleMessages Evergreen.V109.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (LastTypedAt Evergreen.V109.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V109.Message.MessageState Evergreen.V109.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V109.VisibleMessages.VisibleMessages Evergreen.V109.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (LastTypedAt Evergreen.V109.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V109.Slack.Id Evergreen.V109.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V109.Message.Message Evergreen.V109.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (LastTypedAt Evergreen.V109.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V109.OneToOne.OneToOne ExternalMessageId (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V109.Discord.Id.Id Evergreen.V109.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V109.Slack.Id Evergreen.V109.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V109.Message.Message Evergreen.V109.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (LastTypedAt Evergreen.V109.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V109.OneToOne.OneToOne ExternalMessageId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V109.OneToOne.OneToOne ExternalChannelId (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)
    }
