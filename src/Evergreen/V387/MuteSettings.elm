module Evergreen.V387.MuteSettings exposing (..)

import Evergreen.V387.Discord
import Evergreen.V387.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId)
    }
