module Evergreen.V343.MuteSettings exposing (..)

import Evergreen.V343.Discord
import Evergreen.V343.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId)
    }
