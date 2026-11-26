module Evergreen.V426.MuteSettings exposing (..)

import Evergreen.V426.Discord
import Evergreen.V426.Id
import Evergreen.V426.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId) MutedSlackWorkspace
    , mutedSlackDms : SeqDict.SeqDict (Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId) MutedChannel
    }
