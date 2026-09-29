module Evergreen.V394.MuteSettings exposing (..)

import Evergreen.V394.Discord
import Evergreen.V394.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId)
    }
