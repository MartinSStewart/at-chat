module Evergreen.V411.MuteSettings exposing (..)

import Evergreen.V411.Discord
import Evergreen.V411.Id
import Evergreen.V411.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId) MutedSlackWorkspace
    }
