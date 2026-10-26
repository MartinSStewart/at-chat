module Evergreen.V413.Route exposing (..)

import Effect.Time
import Evergreen.V413.Discord
import Evergreen.V413.DmChannelId
import Evergreen.V413.Id
import Evergreen.V413.Pagination
import Evergreen.V413.SecretId
import Evergreen.V413.Slack
import Evergreen.V413.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId) (Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V413.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V413.Discord.Id Evergreen.V413.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V413.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId
    , guildId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V413.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V413.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.UserId
    , channelId : Evergreen.V413.Discord.Id Evergreen.V413.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V413.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V413.Slack.Id Evergreen.V413.Slack.ChannelId) Evergreen.V413.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId
    , teamId : Evergreen.V413.Slack.Id Evergreen.V413.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V413.Slack.Id Evergreen.V413.Slack.UserId
    , channelId : Evergreen.V413.Slack.Id Evergreen.V413.Slack.DmChannelId
    , threadRoute : Evergreen.V413.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V413.Id.Id Evergreen.V413.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V413.Id.Id Evergreen.V413.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V413.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V413.SecretId.SecretId Evergreen.V413.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
