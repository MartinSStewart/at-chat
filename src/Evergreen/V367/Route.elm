module Evergreen.V367.Route exposing (..)

import Effect.Time
import Evergreen.V367.Discord
import Evergreen.V367.DmChannelId
import Evergreen.V367.Id
import Evergreen.V367.Pagination
import Evergreen.V367.SecretId
import Evergreen.V367.SessionIdHash
import Evergreen.V367.Slack
import Evergreen.V367.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Maybe (Evergreen.V367.Id.Id Evergreen.V367.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V367.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V367.Discord.Id Evergreen.V367.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V367.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId
    , guildId : Evergreen.V367.Discord.Id Evergreen.V367.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V367.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V367.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V367.Discord.Id Evergreen.V367.Discord.UserId
    , channelId : Evergreen.V367.Discord.Id Evergreen.V367.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V367.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V367.Id.Id Evergreen.V367.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V367.Id.Id Evergreen.V367.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V367.Slack.OAuthCode, Evergreen.V367.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V367.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
