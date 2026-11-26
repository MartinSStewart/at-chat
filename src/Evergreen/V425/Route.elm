module Evergreen.V425.Route exposing (..)

import Effect.Time
import Evergreen.V425.Discord
import Evergreen.V425.DmChannelId
import Evergreen.V425.Id
import Evergreen.V425.Pagination
import Evergreen.V425.SecretId
import Evergreen.V425.Slack
import Evergreen.V425.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V425.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V425.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId
    , guildId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V425.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V425.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId
    , channelId : Evergreen.V425.Discord.Id Evergreen.V425.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V425.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId) Evergreen.V425.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId
    , teamId : Evergreen.V425.Slack.Id Evergreen.V425.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId
    , channelId : Evergreen.V425.Slack.Id Evergreen.V425.Slack.DmChannelId
    , threadRoute : Evergreen.V425.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V425.Id.Id Evergreen.V425.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V425.Id.Id Evergreen.V425.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V425.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V425.SecretId.SecretId Evergreen.V425.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
