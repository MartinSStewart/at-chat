module Evergreen.V412.MuteSettings exposing (..)

import Evergreen.V412.Discord
import Evergreen.V412.Id
import Evergreen.V412.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId) MutedSlackWorkspace
    }
