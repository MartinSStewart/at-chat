module Evergreen.V389.MuteSettings exposing (..)

import Evergreen.V389.Discord
import Evergreen.V389.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V389.Id.Id Evergreen.V389.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId)
    }
