module Evergreen.V348.MuteSettings exposing (..)

import Evergreen.V348.Discord
import Evergreen.V348.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId)
    }
