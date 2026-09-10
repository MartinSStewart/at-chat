module Evergreen.V376.Route exposing (..)

import Effect.Time
import Evergreen.V376.Discord
import Evergreen.V376.DmChannelId
import Evergreen.V376.Id
import Evergreen.V376.Pagination
import Evergreen.V376.SecretId
import Evergreen.V376.SessionIdHash
import Evergreen.V376.Slack
import Evergreen.V376.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId) (Maybe (Evergreen.V376.Id.Id Evergreen.V376.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V376.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V376.Discord.Id Evergreen.V376.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V376.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId
    , guildId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V376.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V376.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.UserId
    , channelId : Evergreen.V376.Discord.Id Evergreen.V376.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V376.Id.Id Evergreen.V376.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V376.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V376.Id.Id Evergreen.V376.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V376.Id.Id Evergreen.V376.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V376.Slack.OAuthCode, Evergreen.V376.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V376.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V376.SecretId.SecretId Evergreen.V376.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
