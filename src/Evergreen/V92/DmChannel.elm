module Evergreen.V92.DmChannel exposing (..)

import Array
import Evergreen.V92.Discord.Id
import Evergreen.V92.Id
import Evergreen.V92.Message
import Evergreen.V92.OneToOne
import Evergreen.V92.Slack
import Evergreen.V92.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V92.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V92.Message.MessageState Evergreen.V92.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V92.VisibleMessages.VisibleMessages Evergreen.V92.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (LastTypedAt Evergreen.V92.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V92.Message.MessageState Evergreen.V92.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V92.VisibleMessages.VisibleMessages Evergreen.V92.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (LastTypedAt Evergreen.V92.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V92.Slack.Id Evergreen.V92.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V92.Message.Message Evergreen.V92.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (LastTypedAt Evergreen.V92.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V92.OneToOne.OneToOne ExternalMessageId (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V92.Discord.Id.Id Evergreen.V92.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V92.Slack.Id Evergreen.V92.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V92.Message.Message Evergreen.V92.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (LastTypedAt Evergreen.V92.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V92.OneToOne.OneToOne ExternalMessageId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V92.OneToOne.OneToOne ExternalChannelId (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)
    }
