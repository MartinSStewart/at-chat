module Evergreen.V385.MuteSettings exposing (..)

import Evergreen.V385.Discord
import Evergreen.V385.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId)
    }
