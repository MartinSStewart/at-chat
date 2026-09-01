module Evergreen.V365.MuteSettings exposing (..)

import Evergreen.V365.Discord
import Evergreen.V365.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId)
    }
