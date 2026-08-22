module Evergreen.V360.Route exposing (..)

import Effect.Time
import Evergreen.V360.Discord
import Evergreen.V360.DmChannelId
import Evergreen.V360.Id
import Evergreen.V360.Pagination
import Evergreen.V360.SecretId
import Evergreen.V360.SessionIdHash
import Evergreen.V360.Slack
import Evergreen.V360.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId) (Maybe (Evergreen.V360.Id.Id Evergreen.V360.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V360.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V360.Discord.Id Evergreen.V360.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V360.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId
    , guildId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V360.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V360.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.UserId
    , channelId : Evergreen.V360.Discord.Id Evergreen.V360.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V360.Id.Id Evergreen.V360.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V360.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V360.Id.Id Evergreen.V360.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V360.Id.Id Evergreen.V360.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V360.Slack.OAuthCode, Evergreen.V360.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V360.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V360.SecretId.SecretId Evergreen.V360.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
