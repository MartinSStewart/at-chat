module Evergreen.V381.MuteSettings exposing (..)

import Evergreen.V381.Discord
import Evergreen.V381.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId)
    }
