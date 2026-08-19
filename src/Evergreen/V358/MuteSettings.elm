module Evergreen.V358.MuteSettings exposing (..)

import Evergreen.V358.Discord
import Evergreen.V358.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId)
    }
