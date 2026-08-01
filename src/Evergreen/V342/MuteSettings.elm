module Evergreen.V342.MuteSettings exposing (..)

import Evergreen.V342.Discord
import Evergreen.V342.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId)
    }
