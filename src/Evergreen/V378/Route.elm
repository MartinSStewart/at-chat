module Evergreen.V378.Route exposing (..)

import Effect.Time
import Evergreen.V378.Discord
import Evergreen.V378.DmChannelId
import Evergreen.V378.Id
import Evergreen.V378.Pagination
import Evergreen.V378.SecretId
import Evergreen.V378.SessionIdHash
import Evergreen.V378.Slack
import Evergreen.V378.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Maybe (Evergreen.V378.Id.Id Evergreen.V378.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V378.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V378.Discord.Id Evergreen.V378.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V378.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId
    , guildId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V378.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V378.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.UserId
    , channelId : Evergreen.V378.Discord.Id Evergreen.V378.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V378.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V378.Id.Id Evergreen.V378.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V378.Id.Id Evergreen.V378.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V378.Slack.OAuthCode, Evergreen.V378.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V378.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
