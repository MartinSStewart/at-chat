module Evergreen.V340.MuteSettings exposing (..)

import Evergreen.V340.Discord
import Evergreen.V340.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId)
    }
