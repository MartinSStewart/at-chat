module Evergreen.V108.DmChannel exposing (..)

import Array
import Evergreen.V108.Discord.Id
import Evergreen.V108.Id
import Evergreen.V108.Message
import Evergreen.V108.OneToOne
import Evergreen.V108.Slack
import Evergreen.V108.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V108.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V108.Message.MessageState Evergreen.V108.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V108.VisibleMessages.VisibleMessages Evergreen.V108.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (LastTypedAt Evergreen.V108.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V108.Message.MessageState Evergreen.V108.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V108.VisibleMessages.VisibleMessages Evergreen.V108.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (LastTypedAt Evergreen.V108.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V108.Slack.Id Evergreen.V108.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V108.Message.Message Evergreen.V108.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (LastTypedAt Evergreen.V108.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V108.OneToOne.OneToOne ExternalMessageId (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V108.Discord.Id.Id Evergreen.V108.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V108.Slack.Id Evergreen.V108.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V108.Message.Message Evergreen.V108.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (LastTypedAt Evergreen.V108.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V108.OneToOne.OneToOne ExternalMessageId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V108.OneToOne.OneToOne ExternalChannelId (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)
    }
