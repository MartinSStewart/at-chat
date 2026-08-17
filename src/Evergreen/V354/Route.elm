module Evergreen.V354.Route exposing (..)

import Effect.Time
import Evergreen.V354.Discord
import Evergreen.V354.DmChannelId
import Evergreen.V354.Id
import Evergreen.V354.Pagination
import Evergreen.V354.SecretId
import Evergreen.V354.SessionIdHash
import Evergreen.V354.Slack
import Evergreen.V354.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId) (Maybe (Evergreen.V354.Id.Id Evergreen.V354.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V354.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V354.Discord.Id Evergreen.V354.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V354.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId
    , guildId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V354.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V354.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.UserId
    , channelId : Evergreen.V354.Discord.Id Evergreen.V354.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V354.Id.Id Evergreen.V354.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V354.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V354.Id.Id Evergreen.V354.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V354.Id.Id Evergreen.V354.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V354.Slack.OAuthCode, Evergreen.V354.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V354.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V354.SecretId.SecretId Evergreen.V354.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
