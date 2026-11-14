module Evergreen.V422.Route exposing (..)

import Effect.Time
import Evergreen.V422.Discord
import Evergreen.V422.DmChannelId
import Evergreen.V422.Id
import Evergreen.V422.Pagination
import Evergreen.V422.SecretId
import Evergreen.V422.Slack
import Evergreen.V422.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId) (Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V422.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V422.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId
    , guildId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V422.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V422.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId
    , channelId : Evergreen.V422.Discord.Id Evergreen.V422.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V422.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId) Evergreen.V422.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId
    , teamId : Evergreen.V422.Slack.Id Evergreen.V422.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId
    , channelId : Evergreen.V422.Slack.Id Evergreen.V422.Slack.DmChannelId
    , threadRoute : Evergreen.V422.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V422.Id.Id Evergreen.V422.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V422.Id.Id Evergreen.V422.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V422.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V422.SecretId.SecretId Evergreen.V422.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
