module Evergreen.V377.Route exposing (..)

import Effect.Time
import Evergreen.V377.Discord
import Evergreen.V377.DmChannelId
import Evergreen.V377.Id
import Evergreen.V377.Pagination
import Evergreen.V377.SecretId
import Evergreen.V377.SessionIdHash
import Evergreen.V377.Slack
import Evergreen.V377.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Maybe (Evergreen.V377.Id.Id Evergreen.V377.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V377.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V377.Discord.Id Evergreen.V377.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V377.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId
    , guildId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V377.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V377.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.UserId
    , channelId : Evergreen.V377.Discord.Id Evergreen.V377.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V377.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V377.Id.Id Evergreen.V377.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V377.Id.Id Evergreen.V377.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V377.Slack.OAuthCode, Evergreen.V377.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V377.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
