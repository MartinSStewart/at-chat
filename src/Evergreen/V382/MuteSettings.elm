module Evergreen.V382.MuteSettings exposing (..)

import Evergreen.V382.Discord
import Evergreen.V382.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId)
    }
