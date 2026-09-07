module Evergreen.V372.MuteSettings exposing (..)

import Evergreen.V372.Discord
import Evergreen.V372.Id
import SeqDict
import SeqSet


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqSet.SeqSet (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet.SeqSet (Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId)
    }
