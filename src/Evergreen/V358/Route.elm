module Evergreen.V358.Route exposing (..)

import Effect.Time
import Evergreen.V358.Discord
import Evergreen.V358.DmChannelId
import Evergreen.V358.Id
import Evergreen.V358.Pagination
import Evergreen.V358.SecretId
import Evergreen.V358.SessionIdHash
import Evergreen.V358.Slack
import Evergreen.V358.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId) (Maybe (Evergreen.V358.Id.Id Evergreen.V358.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V358.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V358.Discord.Id Evergreen.V358.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V358.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId
    , guildId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V358.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V358.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.UserId
    , channelId : Evergreen.V358.Discord.Id Evergreen.V358.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V358.Id.Id Evergreen.V358.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V358.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V358.Id.Id Evergreen.V358.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V358.Id.Id Evergreen.V358.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V358.Slack.OAuthCode, Evergreen.V358.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V358.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V358.SecretId.SecretId Evergreen.V358.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
