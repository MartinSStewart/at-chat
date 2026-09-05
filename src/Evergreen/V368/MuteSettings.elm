module Evergreen.V368.MuteSettings exposing (..)

import Evergreen.V368.Discord
import Evergreen.V368.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId)
    }
