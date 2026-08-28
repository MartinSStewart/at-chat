module Evergreen.V364.MuteSettings exposing (..)

import Evergreen.V364.Discord
import Evergreen.V364.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId)
    }
