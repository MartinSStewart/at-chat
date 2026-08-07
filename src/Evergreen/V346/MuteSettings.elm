module Evergreen.V346.MuteSettings exposing (..)

import Evergreen.V346.Discord
import Evergreen.V346.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId)
    }
