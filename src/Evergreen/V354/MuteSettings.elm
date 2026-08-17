module Evergreen.V354.MuteSettings exposing (..)

import Evergreen.V354.Discord
import Evergreen.V354.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId)
    }
