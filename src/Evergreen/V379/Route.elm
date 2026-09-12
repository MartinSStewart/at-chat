module Evergreen.V379.Route exposing (..)

import Effect.Time
import Evergreen.V379.Discord
import Evergreen.V379.DmChannelId
import Evergreen.V379.Id
import Evergreen.V379.Pagination
import Evergreen.V379.SecretId
import Evergreen.V379.SessionIdHash
import Evergreen.V379.Slack
import Evergreen.V379.UserSession


type Overlay
    = E2eeInfoOverlay
    | UserOptionsOverlay


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Maybe (Evergreen.V379.Id.Id Evergreen.V379.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V379.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V379.Discord.Id Evergreen.V379.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V379.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId
    , guildId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DmRouteData =
    { channelId : Evergreen.V379.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V379.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    , overlay : Maybe Overlay
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.UserId
    , channelId : Evergreen.V379.Discord.Id Evergreen.V379.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V379.UserSession.ChannelHeaderTab
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
        { highlightLog : Maybe (Evergreen.V379.Id.Id Evergreen.V379.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V379.Id.Id Evergreen.V379.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile (Maybe Overlay)
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V379.Slack.OAuthCode, Evergreen.V379.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V379.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
