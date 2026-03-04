module Evergreen.V125.DmChannel exposing (..)

import Array
import Effect.Time
import Evergreen.V125.Discord
import Evergreen.V125.Discord.Id
import Evergreen.V125.Id
import Evergreen.V125.Message
import Evergreen.V125.NonemptySet
import Evergreen.V125.OneToOne
import Evergreen.V125.Thread
import Evergreen.V125.VisibleMessages
import SeqDict


type DiscordChannelReloadingStatus
    = DiscordChannel_NotReloading
    | DiscordChannel_Reloading Effect.Time.Posix
    | DiscordChannel_LastReloadFailed Effect.Time.Posix Evergreen.V125.Discord.HttpError


type alias FrontendDmChannel =
    { messages : Array.Array (Evergreen.V125.Message.MessageState Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))
    , visibleMessages : Evergreen.V125.VisibleMessages.VisibleMessages Evergreen.V125.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Thread.FrontendThread
    }


type alias DiscordFrontendDmChannel =
    { messages : Array.Array (Evergreen.V125.Message.MessageState Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    , visibleMessages : Evergreen.V125.VisibleMessages.VisibleMessages Evergreen.V125.Id.ChannelMessageId
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , members : Evergreen.V125.NonemptySet.NonemptySet (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    }


type DmChannelId
    = DmChannelId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)


type alias DmChannel =
    { messages : Array.Array (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , threads : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) Evergreen.V125.Thread.BackendThread
    }


type alias DiscordDmChannel =
    { messages : Array.Array (Evergreen.V125.Message.Message Evergreen.V125.Id.ChannelMessageId (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId))
    , lastTypedAt : SeqDict.SeqDict (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId) (Evergreen.V125.Thread.LastTypedAt Evergreen.V125.Id.ChannelMessageId)
    , linkedMessageIds : Evergreen.V125.OneToOne.OneToOne (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.MessageId) (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)
    , members : Evergreen.V125.NonemptySet.NonemptySet (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId)
    , isReloading : DiscordChannelReloadingStatus
    }
