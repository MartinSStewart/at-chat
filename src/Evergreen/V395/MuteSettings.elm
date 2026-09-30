module Evergreen.V395.MuteSettings exposing (..)

import Evergreen.V395.Discord
import Evergreen.V395.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId)
    }
