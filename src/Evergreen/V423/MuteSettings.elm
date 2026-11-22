module Evergreen.V423.MuteSettings exposing (..)

import Evergreen.V423.Discord
import Evergreen.V423.Id
import Evergreen.V423.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId) MutedSlackWorkspace
    , mutedSlackDms : SeqDict.SeqDict (Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId) MutedChannel
    }
