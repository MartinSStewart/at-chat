module Evergreen.V359.MuteSettings exposing (..)

import Evergreen.V359.Discord
import Evergreen.V359.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId)
    }
