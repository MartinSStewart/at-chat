module Evergreen.V411.Route exposing (..)

import Effect.Time
import Evergreen.V411.Discord
import Evergreen.V411.DmChannelId
import Evergreen.V411.Id
import Evergreen.V411.Pagination
import Evergreen.V411.SecretId
import Evergreen.V411.Slack
import Evergreen.V411.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V411.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V411.SecretId.SecretId Evergreen.V411.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V411.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId
    , guildId : Evergreen.V411.Discord.Id Evergreen.V411.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V411.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V411.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId
    , channelId : Evergreen.V411.Discord.Id Evergreen.V411.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V411.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId) Evergreen.V411.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId
    , teamId : Evergreen.V411.Slack.Id Evergreen.V411.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId
    , channelId : Evergreen.V411.Slack.Id Evergreen.V411.Slack.DmChannelId
    , threadRoute : Evergreen.V411.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V411.Id.Id Evergreen.V411.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V411.Id.Id Evergreen.V411.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V411.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V411.SecretId.SecretId Evergreen.V411.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
