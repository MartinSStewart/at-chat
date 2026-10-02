module Evergreen.V396.MuteSettings exposing (..)

import Evergreen.V396.Discord
import Evergreen.V396.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId)
    }
