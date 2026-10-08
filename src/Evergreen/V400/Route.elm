module Evergreen.V400.Route exposing (..)

import Effect.Time
import Evergreen.V400.Discord
import Evergreen.V400.DmChannelId
import Evergreen.V400.Id
import Evergreen.V400.Pagination
import Evergreen.V400.SecretId
import Evergreen.V400.SessionIdHash
import Evergreen.V400.Slack
import Evergreen.V400.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId) (Maybe (Evergreen.V400.Id.Id Evergreen.V400.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V400.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V400.SecretId.SecretId Evergreen.V400.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V400.Discord.Id Evergreen.V400.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V400.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId
    , guildId : Evergreen.V400.Discord.Id Evergreen.V400.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V400.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V400.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V400.Discord.Id Evergreen.V400.Discord.UserId
    , channelId : Evergreen.V400.Discord.Id Evergreen.V400.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V400.Id.Id Evergreen.V400.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V400.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V400.Id.Id Evergreen.V400.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V400.Id.Id Evergreen.V400.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V400.Slack.OAuthCode, Evergreen.V400.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V400.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V400.SecretId.SecretId Evergreen.V400.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
