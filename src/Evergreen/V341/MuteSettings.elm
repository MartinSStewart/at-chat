module Evergreen.V341.MuteSettings exposing (..)

import Evergreen.V341.Discord
import Evergreen.V341.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId)
    }
