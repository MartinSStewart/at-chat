module Evergreen.V357.Route exposing (..)

import Effect.Time
import Evergreen.V357.Discord
import Evergreen.V357.DmChannelId
import Evergreen.V357.Id
import Evergreen.V357.Pagination
import Evergreen.V357.SecretId
import Evergreen.V357.SessionIdHash
import Evergreen.V357.Slack
import Evergreen.V357.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId) (Maybe (Evergreen.V357.Id.Id Evergreen.V357.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V357.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V357.Discord.Id Evergreen.V357.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V357.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId
    , guildId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V357.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V357.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.UserId
    , channelId : Evergreen.V357.Discord.Id Evergreen.V357.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V357.Id.Id Evergreen.V357.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V357.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V357.Id.Id Evergreen.V357.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V357.Id.Id Evergreen.V357.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V357.Slack.OAuthCode, Evergreen.V357.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V357.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V357.SecretId.SecretId Evergreen.V357.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
