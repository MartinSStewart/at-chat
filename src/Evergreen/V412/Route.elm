module Evergreen.V412.Route exposing (..)

import Effect.Time
import Evergreen.V412.Discord
import Evergreen.V412.DmChannelId
import Evergreen.V412.Id
import Evergreen.V412.Pagination
import Evergreen.V412.SecretId
import Evergreen.V412.Slack
import Evergreen.V412.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V412.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V412.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId
    , guildId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V412.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V412.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId
    , channelId : Evergreen.V412.Discord.Id Evergreen.V412.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V412.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId) Evergreen.V412.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId
    , teamId : Evergreen.V412.Slack.Id Evergreen.V412.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId
    , channelId : Evergreen.V412.Slack.Id Evergreen.V412.Slack.DmChannelId
    , threadRoute : Evergreen.V412.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V412.Id.Id Evergreen.V412.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V412.Id.Id Evergreen.V412.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V412.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V412.SecretId.SecretId Evergreen.V412.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
