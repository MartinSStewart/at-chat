module Evergreen.V401.Route exposing (..)

import Effect.Time
import Evergreen.V401.Discord
import Evergreen.V401.DmChannelId
import Evergreen.V401.Id
import Evergreen.V401.Pagination
import Evergreen.V401.SecretId
import Evergreen.V401.SessionIdHash
import Evergreen.V401.Slack
import Evergreen.V401.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V401.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V401.Discord.Id Evergreen.V401.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V401.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId
    , guildId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V401.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V401.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.UserId
    , channelId : Evergreen.V401.Discord.Id Evergreen.V401.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V401.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V401.Id.Id Evergreen.V401.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V401.Id.Id Evergreen.V401.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V401.Slack.OAuthCode, Evergreen.V401.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V401.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V401.SecretId.SecretId Evergreen.V401.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
