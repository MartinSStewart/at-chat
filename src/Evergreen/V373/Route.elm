module Evergreen.V373.Route exposing (..)

import Effect.Time
import Evergreen.V373.Discord
import Evergreen.V373.DmChannelId
import Evergreen.V373.Id
import Evergreen.V373.Pagination
import Evergreen.V373.SecretId
import Evergreen.V373.SessionIdHash
import Evergreen.V373.Slack
import Evergreen.V373.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId) (Maybe (Evergreen.V373.Id.Id Evergreen.V373.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V373.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V373.Discord.Id Evergreen.V373.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V373.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId
    , guildId : Evergreen.V373.Discord.Id Evergreen.V373.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V373.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V373.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V373.Discord.Id Evergreen.V373.Discord.UserId
    , channelId : Evergreen.V373.Discord.Id Evergreen.V373.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V373.Id.Id Evergreen.V373.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V373.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V373.Id.Id Evergreen.V373.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V373.Id.Id Evergreen.V373.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V373.Slack.OAuthCode, Evergreen.V373.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V373.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V373.SecretId.SecretId Evergreen.V373.Id.GamePublicId)
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
