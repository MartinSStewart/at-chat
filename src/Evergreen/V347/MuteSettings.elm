module Evergreen.V347.MuteSettings exposing (..)

import Evergreen.V347.Discord
import Evergreen.V347.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId)
    }
