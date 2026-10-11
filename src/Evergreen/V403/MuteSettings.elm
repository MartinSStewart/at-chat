module Evergreen.V403.MuteSettings exposing (..)

import Evergreen.V403.Discord
import Evergreen.V403.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId) IsMuted
    }
