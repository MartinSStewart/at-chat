module Evergreen.V398.Route exposing (..)

import Effect.Time
import Evergreen.V398.Discord
import Evergreen.V398.DmChannelId
import Evergreen.V398.Id
import Evergreen.V398.Pagination
import Evergreen.V398.SecretId
import Evergreen.V398.SessionIdHash
import Evergreen.V398.Slack
import Evergreen.V398.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId) (Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V398.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V398.Discord.Id Evergreen.V398.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V398.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId
    , guildId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V398.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V398.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.UserId
    , channelId : Evergreen.V398.Discord.Id Evergreen.V398.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V398.Id.Id Evergreen.V398.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V398.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V398.Id.Id Evergreen.V398.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V398.Id.Id Evergreen.V398.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V398.Slack.OAuthCode, Evergreen.V398.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V398.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V398.SecretId.SecretId Evergreen.V398.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
