module Evergreen.V386.MuteSettings exposing (..)

import Evergreen.V386.Discord
import Evergreen.V386.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V386.Discord.Id Evergreen.V386.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V386.Discord.Id Evergreen.V386.Discord.PrivateChannelId)
    }
