module Evergreen.V363.MuteSettings exposing (..)

import Evergreen.V363.Discord
import Evergreen.V363.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId)
    }
