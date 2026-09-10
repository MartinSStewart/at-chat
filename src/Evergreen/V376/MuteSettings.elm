module Evergreen.V376.MuteSettings exposing (..)

import Evergreen.V376.Discord
import Evergreen.V376.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId)
    }
