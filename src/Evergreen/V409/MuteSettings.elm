module Evergreen.V409.MuteSettings exposing (..)

import Evergreen.V409.Discord
import Evergreen.V409.Id
import Evergreen.V409.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId) MutedSlackWorkspace
    }
