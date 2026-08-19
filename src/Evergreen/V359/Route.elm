module Evergreen.V359.Route exposing (..)

import Effect.Time
import Evergreen.V359.Discord
import Evergreen.V359.DmChannelId
import Evergreen.V359.Id
import Evergreen.V359.Pagination
import Evergreen.V359.SecretId
import Evergreen.V359.SessionIdHash
import Evergreen.V359.Slack
import Evergreen.V359.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId) (Maybe (Evergreen.V359.Id.Id Evergreen.V359.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V359.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V359.Discord.Id Evergreen.V359.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V359.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId
    , guildId : Evergreen.V359.Discord.Id Evergreen.V359.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V359.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V359.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V359.Discord.Id Evergreen.V359.Discord.UserId
    , channelId : Evergreen.V359.Discord.Id Evergreen.V359.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V359.Id.Id Evergreen.V359.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V359.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V359.Id.Id Evergreen.V359.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V359.Id.Id Evergreen.V359.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V359.Slack.OAuthCode, Evergreen.V359.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V359.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V359.SecretId.SecretId Evergreen.V359.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
