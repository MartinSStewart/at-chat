module Evergreen.V426.Route exposing (..)

import Effect.Time
import Evergreen.V426.Discord
import Evergreen.V426.DmChannelId
import Evergreen.V426.Id
import Evergreen.V426.Pagination
import Evergreen.V426.SecretId
import Evergreen.V426.Slack
import Evergreen.V426.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId) (Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V426.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V426.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId
    , guildId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V426.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V426.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId
    , channelId : Evergreen.V426.Discord.Id Evergreen.V426.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V426.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId) Evergreen.V426.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId
    , teamId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId
    , channelId : Evergreen.V426.Slack.Id Evergreen.V426.Slack.DmChannelId
    , threadRoute : Evergreen.V426.Id.ThreadRouteWithMaybeMessage
    , showMembersTab : ShowChannelSettings
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
        { highlightLog : Maybe (Evergreen.V426.Id.Id Evergreen.V426.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V426.Id.Id Evergreen.V426.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V426.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V426.SecretId.SecretId Evergreen.V426.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
