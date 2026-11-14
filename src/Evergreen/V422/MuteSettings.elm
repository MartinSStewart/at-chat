module Evergreen.V422.MuteSettings exposing (..)

import Evergreen.V422.Discord
import Evergreen.V422.Id
import Evergreen.V422.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId) MutedSlackWorkspace
    , mutedSlackDms : SeqDict.SeqDict (Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId) MutedChannel
    }
