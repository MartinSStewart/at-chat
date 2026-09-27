module Evergreen.V388.MuteSettings exposing (..)

import Evergreen.V388.Discord
import Evergreen.V388.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V388.Discord.Id Evergreen.V388.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V388.Discord.Id Evergreen.V388.Discord.PrivateChannelId)
    }
