module Evergreen.V365.Route exposing (..)

import Effect.Time
import Evergreen.V365.Discord
import Evergreen.V365.DmChannelId
import Evergreen.V365.Id
import Evergreen.V365.Pagination
import Evergreen.V365.SecretId
import Evergreen.V365.SessionIdHash
import Evergreen.V365.Slack
import Evergreen.V365.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Maybe (Evergreen.V365.Id.Id Evergreen.V365.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V365.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V365.Discord.Id Evergreen.V365.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V365.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId
    , guildId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V365.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V365.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.UserId
    , channelId : Evergreen.V365.Discord.Id Evergreen.V365.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V365.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V365.Id.Id Evergreen.V365.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V365.Id.Id Evergreen.V365.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V365.Slack.OAuthCode, Evergreen.V365.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V365.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
