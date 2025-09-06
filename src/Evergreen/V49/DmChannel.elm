module Evergreen.V49.DmChannel exposing (..)

import Array
import Evergreen.V49.Discord.Id
import Evergreen.V49.Id
import Evergreen.V49.Message
import Evergreen.V49.OneToOne
import Evergreen.V49.Slack
import SeqDict
import Time


type alias VisibleMessages messageId =
    { oldest : Evergreen.V49.Id.Id messageId
    , count : Int
    }


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V49.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V49.Message.MessageState Evergreen.V49.Id.ThreadMessageId)
    , visibleMessages : VisibleMessages Evergreen.V49.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (LastTypedAt Evergreen.V49.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V49.Message.MessageState Evergreen.V49.Id.ChannelMessageId)
    , visibleMessages : VisibleMessages Evergreen.V49.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (LastTypedAt Evergreen.V49.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V49.Slack.Id Evergreen.V49.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V49.Message.Message Evergreen.V49.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (LastTypedAt Evergreen.V49.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V49.OneToOne.OneToOne ExternalMessageId (Evergreen.V49.Id.Id Evergreen.V49.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V49.Discord.Id.Id Evergreen.V49.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V49.Slack.Id Evergreen.V49.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V49.Message.Message Evergreen.V49.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (LastTypedAt Evergreen.V49.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V49.OneToOne.OneToOne ExternalMessageId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V49.OneToOne.OneToOne ExternalChannelId (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelMessageId)
    }
