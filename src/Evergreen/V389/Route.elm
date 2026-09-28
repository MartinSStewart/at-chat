module Evergreen.V389.Route exposing (..)

import Effect.Time
import Evergreen.V389.Discord
import Evergreen.V389.DmChannelId
import Evergreen.V389.Id
import Evergreen.V389.Pagination
import Evergreen.V389.SecretId
import Evergreen.V389.SessionIdHash
import Evergreen.V389.Slack
import Evergreen.V389.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId) (Maybe (Evergreen.V389.Id.Id Evergreen.V389.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V389.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V389.Discord.Id Evergreen.V389.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V389.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId
    , guildId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V389.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V389.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.UserId
    , channelId : Evergreen.V389.Discord.Id Evergreen.V389.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V389.Id.Id Evergreen.V389.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V389.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V389.Id.Id Evergreen.V389.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V389.Id.Id Evergreen.V389.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V389.Slack.OAuthCode, Evergreen.V389.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V389.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V389.SecretId.SecretId Evergreen.V389.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
