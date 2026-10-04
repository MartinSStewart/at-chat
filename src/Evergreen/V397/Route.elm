module Evergreen.V397.Route exposing (..)

import Effect.Time
import Evergreen.V397.Discord
import Evergreen.V397.DmChannelId
import Evergreen.V397.Id
import Evergreen.V397.Pagination
import Evergreen.V397.SecretId
import Evergreen.V397.SessionIdHash
import Evergreen.V397.Slack
import Evergreen.V397.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V397.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V397.Discord.Id Evergreen.V397.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V397.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId
    , guildId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V397.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V397.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.UserId
    , channelId : Evergreen.V397.Discord.Id Evergreen.V397.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V397.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V397.Id.Id Evergreen.V397.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V397.Id.Id Evergreen.V397.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V397.Slack.OAuthCode, Evergreen.V397.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | PrivacyRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V397.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V397.SecretId.SecretId Evergreen.V397.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
