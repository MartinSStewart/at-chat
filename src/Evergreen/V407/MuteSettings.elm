module Evergreen.V407.MuteSettings exposing (..)

import Evergreen.V407.Discord
import Evergreen.V407.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId) IsMuted
    }
