module Evergreen.V419.MuteSettings exposing (..)

import Evergreen.V419.Discord
import Evergreen.V419.Id
import Evergreen.V419.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId) MutedSlackWorkspace
    }
