module Evergreen.V417.MuteSettings exposing (..)

import Evergreen.V417.Discord
import Evergreen.V417.Id
import Evergreen.V417.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId) MutedSlackWorkspace
    }
