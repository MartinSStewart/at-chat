module Evergreen.V400.MuteSettings exposing (..)

import Evergreen.V400.Discord
import Evergreen.V400.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V400.Id.Id Evergreen.V400.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId) IsMuted
    }
