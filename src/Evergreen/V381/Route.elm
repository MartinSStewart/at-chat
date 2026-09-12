module Evergreen.V381.Route exposing (..)

import Effect.Time
import Evergreen.V381.Discord
import Evergreen.V381.DmChannelId
import Evergreen.V381.Id
import Evergreen.V381.Pagination
import Evergreen.V381.SecretId
import Evergreen.V381.SessionIdHash
import Evergreen.V381.Slack
import Evergreen.V381.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Maybe (Evergreen.V381.Id.Id Evergreen.V381.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V381.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V381.Discord.Id Evergreen.V381.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V381.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId
    , guildId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V381.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V381.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.UserId
    , channelId : Evergreen.V381.Discord.Id Evergreen.V381.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V381.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute (Maybe Overlay)
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V381.Id.Id Evergreen.V381.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V381.Id.Id Evergreen.V381.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V381.Slack.OAuthCode, Evergreen.V381.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V381.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
