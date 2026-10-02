module Evergreen.V396.Route exposing (..)

import Effect.Time
import Evergreen.V396.Discord
import Evergreen.V396.DmChannelId
import Evergreen.V396.Id
import Evergreen.V396.Pagination
import Evergreen.V396.SecretId
import Evergreen.V396.SessionIdHash
import Evergreen.V396.Slack
import Evergreen.V396.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId) (Maybe (Evergreen.V396.Id.Id Evergreen.V396.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V396.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V396.Discord.Id Evergreen.V396.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V396.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId
    , guildId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V396.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V396.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.UserId
    , channelId : Evergreen.V396.Discord.Id Evergreen.V396.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V396.Id.Id Evergreen.V396.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V396.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V396.Id.Id Evergreen.V396.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V396.Id.Id Evergreen.V396.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V396.Slack.OAuthCode, Evergreen.V396.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V396.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V396.SecretId.SecretId Evergreen.V396.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
