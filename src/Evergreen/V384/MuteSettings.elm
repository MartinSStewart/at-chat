module Evergreen.V384.MuteSettings exposing (..)

import Evergreen.V384.Discord
import Evergreen.V384.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V384.Id.Id Evergreen.V384.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId)
    }
