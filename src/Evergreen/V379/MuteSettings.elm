module Evergreen.V379.MuteSettings exposing (..)

import Evergreen.V379.Discord
import Evergreen.V379.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId)
    }
