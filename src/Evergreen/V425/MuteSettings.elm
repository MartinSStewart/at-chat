module Evergreen.V425.MuteSettings exposing (..)

import Evergreen.V425.Discord
import Evergreen.V425.Id
import Evergreen.V425.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId) MutedSlackWorkspace
    , mutedSlackDms : SeqDict.SeqDict (Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId) MutedChannel
    }
