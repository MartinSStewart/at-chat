module Evergreen.V345.MuteSettings exposing (..)

import Evergreen.V345.Discord
import Evergreen.V345.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)
    }
