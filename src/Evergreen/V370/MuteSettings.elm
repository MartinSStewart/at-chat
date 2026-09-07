module Evergreen.V370.MuteSettings exposing (..)

import Evergreen.V370.Discord
import Evergreen.V370.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V370.Discord.Id Evergreen.V370.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V370.Discord.Id Evergreen.V370.Discord.PrivateChannelId)
    }
