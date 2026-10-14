module Evergreen.V406.Route exposing (..)

import Effect.Time
import Evergreen.V406.Discord
import Evergreen.V406.DmChannelId
import Evergreen.V406.Id
import Evergreen.V406.Pagination
import Evergreen.V406.SecretId
import Evergreen.V406.Slack
import Evergreen.V406.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V406.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V406.Discord.Id Evergreen.V406.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V406.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId
    , guildId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V406.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V406.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.UserId
    , channelId : Evergreen.V406.Discord.Id Evergreen.V406.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V406.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId
    , teamId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.TeamId
    , channelId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.ChannelId
    , viewingMessage : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.UserId
    , channelId : Evergreen.V406.Slack.Id Evergreen.V406.Slack.DmChannelId
    , viewingMessage : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V406.Id.Id Evergreen.V406.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V406.Id.Id Evergreen.V406.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V406.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
