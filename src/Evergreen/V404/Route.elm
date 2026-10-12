module Evergreen.V404.Route exposing (..)

import Effect.Time
import Evergreen.V404.Discord
import Evergreen.V404.DmChannelId
import Evergreen.V404.Id
import Evergreen.V404.Pagination
import Evergreen.V404.SecretId
import Evergreen.V404.SessionIdHash
import Evergreen.V404.Slack
import Evergreen.V404.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay
    | SearchOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V404.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V404.SecretId.SecretId Evergreen.V404.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V404.Discord.Id Evergreen.V404.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V404.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId
    , guildId : Evergreen.V404.Discord.Id Evergreen.V404.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V404.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V404.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V404.Discord.Id Evergreen.V404.Discord.UserId
    , channelId : Evergreen.V404.Discord.Id Evergreen.V404.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V404.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V404.Id.Id Evergreen.V404.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V404.Id.Id Evergreen.V404.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V404.Slack.OAuthCode, Evergreen.V404.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V404.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V404.SecretId.SecretId Evergreen.V404.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
