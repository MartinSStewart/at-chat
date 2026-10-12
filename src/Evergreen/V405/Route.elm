module Evergreen.V405.Route exposing (..)

import Effect.Time
import Evergreen.V405.Discord
import Evergreen.V405.DmChannelId
import Evergreen.V405.Id
import Evergreen.V405.Pagination
import Evergreen.V405.SecretId
import Evergreen.V405.Slack
import Evergreen.V405.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V405.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V405.Discord.Id Evergreen.V405.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V405.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId
    , guildId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V405.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V405.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.UserId
    , channelId : Evergreen.V405.Discord.Id Evergreen.V405.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V405.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId
    , teamId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.TeamId
    , channelId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.ChannelId
    , viewingMessage : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.UserId
    , channelId : Evergreen.V405.Slack.Id Evergreen.V405.Slack.DmChannelId
    , viewingMessage : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V405.Id.Id Evergreen.V405.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V405.Id.Id Evergreen.V405.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V405.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V405.SecretId.SecretId Evergreen.V405.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
