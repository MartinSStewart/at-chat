module Evergreen.V378.MuteSettings exposing (..)

import Evergreen.V378.Discord
import Evergreen.V378.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId)
    }
