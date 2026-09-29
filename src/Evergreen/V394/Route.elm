module Evergreen.V394.Route exposing (..)

import Effect.Time
import Evergreen.V394.Discord
import Evergreen.V394.DmChannelId
import Evergreen.V394.Id
import Evergreen.V394.Pagination
import Evergreen.V394.SecretId
import Evergreen.V394.SessionIdHash
import Evergreen.V394.Slack
import Evergreen.V394.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId) (Maybe (Evergreen.V394.Id.Id Evergreen.V394.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V394.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V394.Discord.Id Evergreen.V394.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V394.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId
    , guildId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V394.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V394.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.UserId
    , channelId : Evergreen.V394.Discord.Id Evergreen.V394.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V394.Id.Id Evergreen.V394.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V394.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V394.Id.Id Evergreen.V394.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V394.Id.Id Evergreen.V394.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V394.Slack.OAuthCode, Evergreen.V394.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V394.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V394.SecretId.SecretId Evergreen.V394.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
