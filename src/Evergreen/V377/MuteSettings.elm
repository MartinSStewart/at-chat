module Evergreen.V377.MuteSettings exposing (..)

import Evergreen.V377.Discord
import Evergreen.V377.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId)
    }
