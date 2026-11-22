module Evergreen.V423.Route exposing (..)

import Effect.Time
import Evergreen.V423.Discord
import Evergreen.V423.DmChannelId
import Evergreen.V423.Id
import Evergreen.V423.Pagination
import Evergreen.V423.SecretId
import Evergreen.V423.Slack
import Evergreen.V423.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId) (Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V423.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V423.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId
    , guildId : Evergreen.V423.Discord.Id Evergreen.V423.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V423.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V423.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId
    , channelId : Evergreen.V423.Discord.Id Evergreen.V423.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V423.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId) Evergreen.V423.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId
    , teamId : Evergreen.V423.Slack.Id Evergreen.V423.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId
    , channelId : Evergreen.V423.Slack.Id Evergreen.V423.Slack.DmChannelId
    , threadRoute : Evergreen.V423.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V423.Id.Id Evergreen.V423.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V423.Id.Id Evergreen.V423.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V423.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V423.SecretId.SecretId Evergreen.V423.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
