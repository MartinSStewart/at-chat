module Evergreen.V385.Route exposing (..)

import Effect.Time
import Evergreen.V385.Discord
import Evergreen.V385.DmChannelId
import Evergreen.V385.Id
import Evergreen.V385.Pagination
import Evergreen.V385.SecretId
import Evergreen.V385.SessionIdHash
import Evergreen.V385.Slack
import Evergreen.V385.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Maybe (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V385.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V385.Discord.Id Evergreen.V385.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V385.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId
    , guildId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V385.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V385.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.UserId
    , channelId : Evergreen.V385.Discord.Id Evergreen.V385.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V385.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V385.Id.Id Evergreen.V385.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V385.Id.Id Evergreen.V385.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V385.Slack.OAuthCode, Evergreen.V385.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V385.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
