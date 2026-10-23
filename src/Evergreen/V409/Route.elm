module Evergreen.V409.Route exposing (..)

import Effect.Time
import Evergreen.V409.Discord
import Evergreen.V409.DmChannelId
import Evergreen.V409.Id
import Evergreen.V409.Pagination
import Evergreen.V409.SecretId
import Evergreen.V409.Slack
import Evergreen.V409.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V409.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V409.Discord.Id Evergreen.V409.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V409.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId
    , guildId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V409.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V409.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.UserId
    , channelId : Evergreen.V409.Discord.Id Evergreen.V409.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V409.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V409.Slack.Id Evergreen.V409.Slack.ChannelId) Evergreen.V409.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId
    , teamId : Evergreen.V409.Slack.Id Evergreen.V409.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V409.Slack.Id Evergreen.V409.Slack.UserId
    , channelId : Evergreen.V409.Slack.Id Evergreen.V409.Slack.DmChannelId
    , threadRoute : Evergreen.V409.Id.ThreadRouteWithMaybeMessage
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData
    | LinkDiscordLimitReachedError


type Route
    = HomePageRoute (Maybe Overlay)
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V409.Id.Id Evergreen.V409.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V409.Id.Id Evergreen.V409.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V409.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V409.SecretId.SecretId Evergreen.V409.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
