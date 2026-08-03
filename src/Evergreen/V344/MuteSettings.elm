module Evergreen.V344.MuteSettings exposing (..)

import Evergreen.V344.Discord
import Evergreen.V344.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId)
    }
