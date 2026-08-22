module Evergreen.V360.MuteSettings exposing (..)

import Evergreen.V360.Discord
import Evergreen.V360.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId)
    }
