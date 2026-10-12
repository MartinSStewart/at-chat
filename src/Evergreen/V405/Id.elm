module Evergreen.V405.Id exposing (..)

import Evergreen.V405.Discord
import Evergreen.V405.Slack


type Id a
    = Id Int


type UserId
    = UserId Never


type GuildId
    = GuildId Never


type ChannelId
    = ChannelId Never


type ChannelMessageId
    = ChannelMessageId Never


type ThreadMessageId
    = ThreadMessageId Never


type QuestionId
    = QuestionId Never


type InviteLinkId
    = InviteLinkId Never


type GamePublicId
    = GoMatchPublicId Never


type alias Viewing_ChannelId =
    { guildId : Id GuildId
    , channelId : Id ChannelId
    }


type alias Viewing_DmId =
    { otherUserId : Id UserId
    }


type GuildOrDmId
    = GuildOrDmId_Guild Viewing_ChannelId
    | GuildOrDmId_Dm Viewing_DmId


type alias Viewing_DiscordChannelId =
    { guildId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId
    , channelId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId
    , currentUserId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId
    }


type alias Viewing_DiscordDmId =
    { currentUserId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId
    , channelId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId
    }


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild Viewing_DiscordChannelId
    | DiscordGuildOrDmId_Dm Viewing_DiscordDmId


type alias Viewing_SlackChannelId =
    { teamId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId
    , channelId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId
    , currentUserId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId
    }


type alias Viewing_SlackDmId =
    { currentUserId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId
    , channelId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId
    }


type SlackGuildOrDmId
    = SlackGuildOrDmId_Workspace Viewing_SlackChannelId
    | SlackGuildOrDmId_Dm Viewing_SlackDmId


type AnyGuildOrDmId
    = GuildOrDmId GuildOrDmId
    | DiscordGuildOrDmId DiscordGuildOrDmId
    | SlackGuildOrDmId SlackGuildOrDmId


type ThreadRoute
    = NoThread
    | ViewThread (Id ChannelMessageId)


type ThreadRouteWithMessage
    = NoThreadWithMessage (Id ChannelMessageId)
    | ViewThreadWithMessage (Id ChannelMessageId) (Id ThreadMessageId)


type CustomEmojiId
    = CustomEmojiId Never


type StickerId
    = StickerId Never


type ExportChannelId
    = ExportChannel_Guild (Id GuildId) (Id ChannelId)
    | ExportChannel_Discord (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId)
    | ExportChannel_Dm (Id UserId)
    | ExportChannel_DiscordDm (Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId) (Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId)


type alias Viewing_DmThreadId =
    { otherUserId : Id UserId
    , threadId : Id ChannelMessageId
    }


type alias Viewing_ChannelThreadId =
    { guildId : Id GuildId
    , channelId : Id ChannelId
    , threadId : Id ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadId =
    { guildId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId
    , channelId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId
    , currentUserId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId
    , threadId : Id ChannelMessageId
    }


type ThreadRouteWithMaybeMessage
    = NoThreadWithMaybeMessage (Maybe (Id ChannelMessageId))
    | ViewThreadWithMaybeMessage (Id ChannelMessageId) (Maybe (Id ThreadMessageId))
