module Evergreen.V402.MuteSettings exposing (..)

import Evergreen.V402.Discord
import Evergreen.V402.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId) IsMuted
    }
