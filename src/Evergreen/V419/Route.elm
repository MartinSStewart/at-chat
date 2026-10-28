module Evergreen.V419.Route exposing (..)

import Effect.Time
import Evergreen.V419.Discord
import Evergreen.V419.DmChannelId
import Evergreen.V419.Id
import Evergreen.V419.Pagination
import Evergreen.V419.SecretId
import Evergreen.V419.Slack
import Evergreen.V419.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V419.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V419.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId
    , guildId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V419.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V419.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId
    , channelId : Evergreen.V419.Discord.Id Evergreen.V419.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V419.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId) Evergreen.V419.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId
    , teamId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId
    , channelId : Evergreen.V419.Slack.Id Evergreen.V419.Slack.DmChannelId
    , threadRoute : Evergreen.V419.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V419.Id.Id Evergreen.V419.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V419.Id.Id Evergreen.V419.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V419.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V419.SecretId.SecretId Evergreen.V419.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
