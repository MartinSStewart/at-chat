module Evergreen.V414.MuteSettings exposing (..)

import Evergreen.V414.Discord
import Evergreen.V414.Id
import Evergreen.V414.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId) MutedSlackWorkspace
    }
