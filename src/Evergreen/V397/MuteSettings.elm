module Evergreen.V397.MuteSettings exposing (..)

import Evergreen.V397.Discord
import Evergreen.V397.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId)
    }
