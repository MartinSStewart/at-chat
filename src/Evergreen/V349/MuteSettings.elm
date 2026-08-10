module Evergreen.V349.MuteSettings exposing (..)

import Evergreen.V349.Discord
import Evergreen.V349.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId)
    }
