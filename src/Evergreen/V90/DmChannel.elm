module Evergreen.V90.DmChannel exposing (..)

import Array
import Evergreen.V90.Discord.Id
import Evergreen.V90.Id
import Evergreen.V90.Message
import Evergreen.V90.OneToOne
import Evergreen.V90.Slack
import Evergreen.V90.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V90.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V90.Message.MessageState Evergreen.V90.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V90.VisibleMessages.VisibleMessages Evergreen.V90.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (LastTypedAt Evergreen.V90.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V90.Message.MessageState Evergreen.V90.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V90.VisibleMessages.VisibleMessages Evergreen.V90.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (LastTypedAt Evergreen.V90.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V90.Slack.Id Evergreen.V90.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V90.Message.Message Evergreen.V90.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (LastTypedAt Evergreen.V90.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V90.OneToOne.OneToOne ExternalMessageId (Evergreen.V90.Id.Id Evergreen.V90.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V90.Discord.Id.Id Evergreen.V90.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V90.Slack.Id Evergreen.V90.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V90.Message.Message Evergreen.V90.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (LastTypedAt Evergreen.V90.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V90.OneToOne.OneToOne ExternalMessageId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V90.OneToOne.OneToOne ExternalChannelId (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId)
    }
