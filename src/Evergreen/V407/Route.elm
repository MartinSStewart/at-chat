module Evergreen.V407.Route exposing (..)

import Effect.Time
import Evergreen.V407.Discord
import Evergreen.V407.DmChannelId
import Evergreen.V407.Id
import Evergreen.V407.Pagination
import Evergreen.V407.SecretId
import Evergreen.V407.Slack
import Evergreen.V407.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V407.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V407.Discord.Id Evergreen.V407.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V407.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId
    , guildId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V407.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V407.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.UserId
    , channelId : Evergreen.V407.Discord.Id Evergreen.V407.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V407.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId
    , teamId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.TeamId
    , channelId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.ChannelId
    , threadRoute : Evergreen.V407.Id.ThreadRouteWithMaybeMessage
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.UserId
    , channelId : Evergreen.V407.Slack.Id Evergreen.V407.Slack.DmChannelId
    , threadRoute : Evergreen.V407.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V407.Id.Id Evergreen.V407.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V407.Id.Id Evergreen.V407.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V407.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V407.SecretId.SecretId Evergreen.V407.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
