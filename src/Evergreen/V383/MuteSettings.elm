module Evergreen.V383.MuteSettings exposing (..)

import Evergreen.V383.Discord
import Evergreen.V383.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V383.Id.Id Evergreen.V383.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V383.Discord.Id Evergreen.V383.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V383.Discord.Id Evergreen.V383.Discord.PrivateChannelId)
    }
