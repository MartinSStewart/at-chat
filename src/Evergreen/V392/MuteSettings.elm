module Evergreen.V392.MuteSettings exposing (..)

import Evergreen.V392.Discord
import Evergreen.V392.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V392.Discord.Id Evergreen.V392.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V392.Discord.Id Evergreen.V392.Discord.PrivateChannelId)
    }
