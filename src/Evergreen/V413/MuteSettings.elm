module Evergreen.V413.MuteSettings exposing (..)

import Evergreen.V413.Discord
import Evergreen.V413.Id
import Evergreen.V413.Slack
import SeqDict


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedChannel =
    { mutedChannel : IsMuted
    , mutedThreads : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) IsMuted
    }


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) MutedChannel
    }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) MutedChannel
    }


type alias MutedSlackWorkspace =
    { mutedWorkspace : IsMuted
    , channels : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) MutedChannel
    }


type alias Model =
    { mutedGuilds : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) MutedGuild
    , mutedDms : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict.SeqDict (Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId) IsMuted
    , mutedSlackWorkspaces : SeqDict.SeqDict (Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId) MutedSlackWorkspace
    }
