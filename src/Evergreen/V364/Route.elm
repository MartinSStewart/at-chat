module Evergreen.V364.Route exposing (..)

import Effect.Time
import Evergreen.V364.Discord
import Evergreen.V364.DmChannelId
import Evergreen.V364.Id
import Evergreen.V364.Pagination
import Evergreen.V364.SecretId
import Evergreen.V364.SessionIdHash
import Evergreen.V364.Slack
import Evergreen.V364.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Maybe (Evergreen.V364.Id.Id Evergreen.V364.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V364.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V364.Discord.Id Evergreen.V364.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V364.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId
    , guildId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V364.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V364.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.UserId
    , channelId : Evergreen.V364.Discord.Id Evergreen.V364.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V364.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V364.Id.Id Evergreen.V364.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V364.Id.Id Evergreen.V364.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V364.Slack.OAuthCode, Evergreen.V364.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V364.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
