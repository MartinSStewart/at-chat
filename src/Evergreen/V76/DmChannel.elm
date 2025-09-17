module Evergreen.V76.DmChannel exposing (..)

import Array
import Evergreen.V76.Discord.Id
import Evergreen.V76.Id
import Evergreen.V76.Message
import Evergreen.V76.OneToOne
import Evergreen.V76.Slack
import Evergreen.V76.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V76.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V76.Message.MessageState Evergreen.V76.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V76.VisibleMessages.VisibleMessages Evergreen.V76.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (LastTypedAt Evergreen.V76.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V76.Message.MessageState Evergreen.V76.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V76.VisibleMessages.VisibleMessages Evergreen.V76.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (LastTypedAt Evergreen.V76.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V76.Slack.Id Evergreen.V76.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V76.Message.Message Evergreen.V76.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (LastTypedAt Evergreen.V76.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V76.OneToOne.OneToOne ExternalMessageId (Evergreen.V76.Id.Id Evergreen.V76.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V76.Discord.Id.Id Evergreen.V76.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V76.Slack.Id Evergreen.V76.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V76.Message.Message Evergreen.V76.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (LastTypedAt Evergreen.V76.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V76.OneToOne.OneToOne ExternalMessageId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V76.OneToOne.OneToOne ExternalChannelId (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId)
    }
