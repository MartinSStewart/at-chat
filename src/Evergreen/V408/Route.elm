module Evergreen.V408.Route exposing (..)

import Effect.Time
import Evergreen.V408.Discord
import Evergreen.V408.DmChannelId
import Evergreen.V408.Id
import Evergreen.V408.Pagination
import Evergreen.V408.SecretId
import Evergreen.V408.Slack
import Evergreen.V408.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId) (Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V408.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V408.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId
    , guildId : Evergreen.V408.Discord.Id Evergreen.V408.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V408.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V408.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId
    , channelId : Evergreen.V408.Discord.Id Evergreen.V408.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V408.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId) Evergreen.V408.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId
    , teamId : Evergreen.V408.Slack.Id Evergreen.V408.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId
    , channelId : Evergreen.V408.Slack.Id Evergreen.V408.Slack.DmChannelId
    , threadRoute : Evergreen.V408.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V408.Id.Id Evergreen.V408.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V408.Id.Id Evergreen.V408.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V408.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V408.SecretId.SecretId Evergreen.V408.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
