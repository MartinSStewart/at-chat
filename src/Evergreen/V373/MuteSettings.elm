module Evergreen.V373.MuteSettings exposing (..)

import Evergreen.V373.Discord
import Evergreen.V373.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId)
    }
