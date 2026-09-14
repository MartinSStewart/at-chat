module Evergreen.V382.Route exposing (..)

import Effect.Time
import Evergreen.V382.Discord
import Evergreen.V382.DmChannelId
import Evergreen.V382.Id
import Evergreen.V382.Pagination
import Evergreen.V382.SecretId
import Evergreen.V382.SessionIdHash
import Evergreen.V382.Slack
import Evergreen.V382.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId) (Maybe (Evergreen.V382.Id.Id Evergreen.V382.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V382.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V382.Discord.Id Evergreen.V382.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V382.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId
    , guildId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V382.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V382.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.UserId
    , channelId : Evergreen.V382.Discord.Id Evergreen.V382.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V382.Id.Id Evergreen.V382.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V382.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V382.Id.Id Evergreen.V382.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V382.Id.Id Evergreen.V382.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V382.Slack.OAuthCode, Evergreen.V382.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V382.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V382.SecretId.SecretId Evergreen.V382.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
