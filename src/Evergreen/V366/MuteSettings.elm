module Evergreen.V366.MuteSettings exposing (..)

import Evergreen.V366.Discord
import Evergreen.V366.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V366.Discord.Id Evergreen.V366.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V366.Discord.Id Evergreen.V366.Discord.PrivateChannelId)
    }
