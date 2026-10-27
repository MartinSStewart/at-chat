module Evergreen.V417.Route exposing (..)

import Effect.Time
import Evergreen.V417.Discord
import Evergreen.V417.DmChannelId
import Evergreen.V417.Id
import Evergreen.V417.Pagination
import Evergreen.V417.SecretId
import Evergreen.V417.Slack
import Evergreen.V417.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V417.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V417.Discord.Id Evergreen.V417.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V417.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId
    , guildId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V417.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V417.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.UserId
    , channelId : Evergreen.V417.Discord.Id Evergreen.V417.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V417.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V417.Slack.Id Evergreen.V417.Slack.ChannelId) Evergreen.V417.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId
    , teamId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.UserId
    , channelId : Evergreen.V417.Slack.Id Evergreen.V417.Slack.DmChannelId
    , threadRoute : Evergreen.V417.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V417.Id.Id Evergreen.V417.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V417.Id.Id Evergreen.V417.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V417.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V417.SecretId.SecretId Evergreen.V417.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
