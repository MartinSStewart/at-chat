module Evergreen.V384.Route exposing (..)

import Effect.Time
import Evergreen.V384.Discord
import Evergreen.V384.DmChannelId
import Evergreen.V384.Id
import Evergreen.V384.Pagination
import Evergreen.V384.SecretId
import Evergreen.V384.SessionIdHash
import Evergreen.V384.Slack
import Evergreen.V384.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId) (Maybe (Evergreen.V384.Id.Id Evergreen.V384.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V384.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V384.Discord.Id Evergreen.V384.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V384.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId
    , guildId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V384.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V384.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.UserId
    , channelId : Evergreen.V384.Discord.Id Evergreen.V384.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V384.Id.Id Evergreen.V384.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V384.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V384.Id.Id Evergreen.V384.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V384.Id.Id Evergreen.V384.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V384.Slack.OAuthCode, Evergreen.V384.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V384.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V384.SecretId.SecretId Evergreen.V384.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
