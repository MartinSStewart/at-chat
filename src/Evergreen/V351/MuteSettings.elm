module Evergreen.V351.MuteSettings exposing (..)

import Evergreen.V351.Discord
import Evergreen.V351.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId)
    }
