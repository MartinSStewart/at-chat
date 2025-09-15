module Evergreen.V61.DmChannel exposing (..)

import Array
import Evergreen.V61.Discord.Id
import Evergreen.V61.Id
import Evergreen.V61.Message
import Evergreen.V61.OneToOne
import Evergreen.V61.Slack
import Evergreen.V61.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V61.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V61.Message.MessageState Evergreen.V61.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V61.VisibleMessages.VisibleMessages Evergreen.V61.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (LastTypedAt Evergreen.V61.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V61.Message.MessageState Evergreen.V61.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V61.VisibleMessages.VisibleMessages Evergreen.V61.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (LastTypedAt Evergreen.V61.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V61.Slack.Id Evergreen.V61.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V61.Message.Message Evergreen.V61.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (LastTypedAt Evergreen.V61.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V61.OneToOne.OneToOne ExternalMessageId (Evergreen.V61.Id.Id Evergreen.V61.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V61.Discord.Id.Id Evergreen.V61.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V61.Slack.Id Evergreen.V61.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V61.Message.Message Evergreen.V61.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (LastTypedAt Evergreen.V61.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V61.OneToOne.OneToOne ExternalMessageId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V61.OneToOne.OneToOne ExternalChannelId (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId)
    }
