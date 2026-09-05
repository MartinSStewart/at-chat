module Evergreen.V368.Route exposing (..)

import Effect.Time
import Evergreen.V368.Discord
import Evergreen.V368.DmChannelId
import Evergreen.V368.Id
import Evergreen.V368.Pagination
import Evergreen.V368.SecretId
import Evergreen.V368.SessionIdHash
import Evergreen.V368.Slack
import Evergreen.V368.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Maybe (Evergreen.V368.Id.Id Evergreen.V368.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V368.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V368.Discord.Id Evergreen.V368.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V368.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId
    , guildId : Evergreen.V368.Discord.Id Evergreen.V368.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V368.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V368.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V368.Discord.Id Evergreen.V368.Discord.UserId
    , channelId : Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V368.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V368.Id.Id Evergreen.V368.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V368.Id.Id Evergreen.V368.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V368.Slack.OAuthCode, Evergreen.V368.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V368.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.GamePublicId)
    | E2eeInfo


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
