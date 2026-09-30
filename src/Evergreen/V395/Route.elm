module Evergreen.V395.Route exposing (..)

import Effect.Time
import Evergreen.V395.Discord
import Evergreen.V395.DmChannelId
import Evergreen.V395.Id
import Evergreen.V395.Pagination
import Evergreen.V395.SecretId
import Evergreen.V395.SessionIdHash
import Evergreen.V395.Slack
import Evergreen.V395.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V395.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V395.Discord.Id Evergreen.V395.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V395.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId
    , guildId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V395.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V395.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.UserId
    , channelId : Evergreen.V395.Discord.Id Evergreen.V395.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V395.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V395.Id.Id Evergreen.V395.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V395.Id.Id Evergreen.V395.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V395.Slack.OAuthCode, Evergreen.V395.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V395.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
