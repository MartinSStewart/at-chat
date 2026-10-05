module Evergreen.V398.MuteSettings exposing (..)

import Evergreen.V398.Discord
import Evergreen.V398.Id
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId) IsMuted
    }
