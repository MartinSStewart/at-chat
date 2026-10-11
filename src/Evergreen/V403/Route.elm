module Evergreen.V403.Route exposing (..)

import Effect.Time
import Evergreen.V403.Discord
import Evergreen.V403.DmChannelId
import Evergreen.V403.Id
import Evergreen.V403.Pagination
import Evergreen.V403.SecretId
import Evergreen.V403.SessionIdHash
import Evergreen.V403.Slack
import Evergreen.V403.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V403.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V403.Discord.Id Evergreen.V403.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V403.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId
    , guildId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V403.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V403.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.UserId
    , channelId : Evergreen.V403.Discord.Id Evergreen.V403.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V403.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V403.Id.Id Evergreen.V403.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V403.Id.Id Evergreen.V403.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V403.Slack.OAuthCode, Evergreen.V403.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V403.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V403.SecretId.SecretId Evergreen.V403.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
