module Evergreen.V408.MuteSettings exposing (..)

import Evergreen.V408.Discord
import Evergreen.V408.Id
import Evergreen.V408.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId) MutedSlackWorkspace
    }
