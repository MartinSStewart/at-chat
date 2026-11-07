module Evergreen.V421.Route exposing (..)

import Effect.Time
import Evergreen.V421.Discord
import Evergreen.V421.DmChannelId
import Evergreen.V421.Id
import Evergreen.V421.Pagination
import Evergreen.V421.SecretId
import Evergreen.V421.Slack
import Evergreen.V421.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId) (Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V421.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V421.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId
    , guildId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V421.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V421.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId
    , channelId : Evergreen.V421.Discord.Id Evergreen.V421.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V421.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type SlackChannelRoute
    = SlackChannel_ChannelRoute (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId) Evergreen.V421.Id.ThreadRouteWithMaybeMessage ShowChannelSettings
    | SlackChannel_WorkspaceSettingsRoute


type alias SlackWorkspaceRouteData =
    { currentSlackUserId : Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId
    , teamId : Evergreen.V421.Slack.Id Evergreen.V421.Slack.TeamId
    , channelRoute : SlackChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias SlackDmRouteData =
    { currentSlackUserId : Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId
    , channelId : Evergreen.V421.Slack.Id Evergreen.V421.Slack.DmChannelId
    , threadRoute : Evergreen.V421.Id.ThreadRouteWithMaybeMessage
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
        { highlightLog : Maybe (Evergreen.V421.Id.Id Evergreen.V421.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V421.Id.Id Evergreen.V421.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | SlackWorkspaceRoute SlackWorkspaceRouteData
    | SlackDmRoute SlackDmRouteData
    | AiChatRoute
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V421.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V421.SecretId.SecretId Evergreen.V421.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
