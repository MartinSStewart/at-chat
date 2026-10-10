module Evergreen.V402.Route exposing (..)

import Effect.Time
import Evergreen.V402.Discord
import Evergreen.V402.DmChannelId
import Evergreen.V402.Id
import Evergreen.V402.Pagination
import Evergreen.V402.SecretId
import Evergreen.V402.SessionIdHash
import Evergreen.V402.Slack
import Evergreen.V402.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId) (Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V402.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V402.Discord.Id Evergreen.V402.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V402.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId
    , guildId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V402.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V402.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.UserId
    , channelId : Evergreen.V402.Discord.Id Evergreen.V402.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V402.Id.Id Evergreen.V402.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V402.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V402.Id.Id Evergreen.V402.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V402.Id.Id Evergreen.V402.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V402.Slack.OAuthCode, Evergreen.V402.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V402.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V402.SecretId.SecretId Evergreen.V402.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
