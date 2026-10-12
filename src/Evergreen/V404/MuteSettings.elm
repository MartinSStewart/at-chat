module Evergreen.V404.MuteSettings exposing (..)

import Evergreen.V404.Discord
import Evergreen.V404.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId) IsMuted
    }
