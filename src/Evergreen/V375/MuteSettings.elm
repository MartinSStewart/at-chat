module Evergreen.V375.MuteSettings exposing (..)

import Evergreen.V375.Discord
import Evergreen.V375.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId)
    }
