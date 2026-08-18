module Evergreen.V357.MuteSettings exposing (..)

import Evergreen.V357.Discord
import Evergreen.V357.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId)
    }
