module Evergreen.V421.MuteSettings exposing (..)

import Evergreen.V421.Discord
import Evergreen.V421.Id
import Evergreen.V421.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId) MutedSlackWorkspace
    }
