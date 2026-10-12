module Evergreen.V405.MuteSettings exposing (..)

import Evergreen.V405.Discord
import Evergreen.V405.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId) IsMuted
    }
