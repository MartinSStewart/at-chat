module Evergreen.V60.DmChannel exposing (..)

import Array
import Evergreen.V60.Discord.Id
import Evergreen.V60.Id
import Evergreen.V60.Message
import Evergreen.V60.OneToOne
import Evergreen.V60.Slack
import Evergreen.V60.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V60.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V60.Message.MessageState Evergreen.V60.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V60.VisibleMessages.VisibleMessages Evergreen.V60.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (LastTypedAt Evergreen.V60.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V60.Message.MessageState Evergreen.V60.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V60.VisibleMessages.VisibleMessages Evergreen.V60.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (LastTypedAt Evergreen.V60.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V60.Slack.Id Evergreen.V60.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V60.Message.Message Evergreen.V60.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (LastTypedAt Evergreen.V60.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V60.OneToOne.OneToOne ExternalMessageId (Evergreen.V60.Id.Id Evergreen.V60.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V60.Discord.Id.Id Evergreen.V60.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V60.Slack.Id Evergreen.V60.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V60.Message.Message Evergreen.V60.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (LastTypedAt Evergreen.V60.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V60.OneToOne.OneToOne ExternalMessageId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V60.OneToOne.OneToOne ExternalChannelId (Evergreen.V60.Id.Id Evergreen.V60.Id.ChannelMessageId)
    }
