module Evergreen.V414.Route exposing (..)

import Effect.Time
import Evergreen.V414.Discord
import Evergreen.V414.DmChannelId
import Evergreen.V414.Id
import Evergreen.V414.Pagination
import Evergreen.V414.SecretId
import Evergreen.V414.Slack
import Evergreen.V414.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId) (Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V414.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V414.SecretId.SecretId Evergreen.V414.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V414.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId
    , guildId : Evergreen.V414.Discord.Id Evergreen.V414.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V414.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V414.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId
    , channelId : Evergreen.V414.Discord.Id Evergreen.V414.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V414.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId) Evergreen.V414.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId
    , teamId : Evergreen.V414.Slack.Id Evergreen.V414.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId
    , channelId : Evergreen.V414.Slack.Id Evergreen.V414.Slack.DmChannelId
    , threadRoute : Evergreen.V414.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V414.Id.Id Evergreen.V414.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V414.Id.Id Evergreen.V414.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V414.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V414.SecretId.SecretId Evergreen.V414.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
