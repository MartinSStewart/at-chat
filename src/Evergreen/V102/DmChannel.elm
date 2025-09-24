module Evergreen.V102.DmChannel exposing (..)

import Array
import Evergreen.V102.Discord.Id
import Evergreen.V102.Id
import Evergreen.V102.Message
import Evergreen.V102.OneToOne
import Evergreen.V102.Slack
import Evergreen.V102.VisibleMessages
import SeqDict
import Time


type alias LastTypedAt messageId =
    { time : Time.Posix
    , messageIndex : Maybe (Evergreen.V102.Id.Id messageId)
    }


type alias FrontendThread =
    { messages : Array.Array (Evergreen.V102.Message.MessageState Evergreen.V102.Id.ThreadMessageId)
    , visibleMessages : Evergreen.V102.VisibleMessages.VisibleMessages Evergreen.V102.Id.ThreadMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (LastTypedAt Evergreen.V102.Id.ThreadMessageId)
    }


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V102.Message.MessageState Evergreen.V102.Id.ChannelMessageId)
    , visibleMessages : Evergreen.V102.VisibleMessages.VisibleMessages Evergreen.V102.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (LastTypedAt Evergreen.V102.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) FrontendThread
    }


type ExternalMessageId
    = DiscordMessageId (Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.MessageId)
    | SlackMessageId (Evergreen.V102.Slack.Id Evergreen.V102.Slack.MessageId)


type alias Thread =
    { messages : Array.Array (Evergreen.V102.Message.Message Evergreen.V102.Id.ThreadMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (LastTypedAt Evergreen.V102.Id.ThreadMessageId)
    , linkedMessageIds : Evergreen.V102.OneToOne.OneToOne ExternalMessageId (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId)
    }


type ExternalChannelId
    = DiscordChannelId (Evergreen.V102.Discord.Id.Id Evergreen.V102.Discord.Id.ChannelId)
    | SlackChannelId (Evergreen.V102.Slack.Id Evergreen.V102.Slack.ChannelId)


type DmChannelId
    = DirectMessageChannelId (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V102.Message.Message Evergreen.V102.Id.ChannelMessageId)
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) (LastTypedAt Evergreen.V102.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V102.OneToOne.OneToOne ExternalMessageId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) Thread
    , linkedThreadIds : Evergreen.V102.OneToOne.OneToOne ExternalChannelId (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)
    }
