module Evergreen.V401.MuteSettings exposing (..)

import Evergreen.V401.Discord
import Evergreen.V401.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId) IsMuted
    }
