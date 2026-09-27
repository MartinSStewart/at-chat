module Evergreen.V387.Route exposing (..)

import Effect.Time
import Evergreen.V387.Discord
import Evergreen.V387.DmChannelId
import Evergreen.V387.Id
import Evergreen.V387.Pagination
import Evergreen.V387.SecretId
import Evergreen.V387.SessionIdHash
import Evergreen.V387.Slack
import Evergreen.V387.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Maybe (Evergreen.V387.Id.Id Evergreen.V387.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V387.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V387.Discord.Id Evergreen.V387.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V387.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId
    , guildId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V387.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V387.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.UserId
    , channelId : Evergreen.V387.Discord.Id Evergreen.V387.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V387.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V387.Id.Id Evergreen.V387.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V387.Id.Id Evergreen.V387.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V387.Slack.OAuthCode, Evergreen.V387.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V387.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
