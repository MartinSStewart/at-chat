module Evergreen.V363.Route exposing (..)

import Effect.Time
import Evergreen.V363.Discord
import Evergreen.V363.DmChannelId
import Evergreen.V363.Id
import Evergreen.V363.Pagination
import Evergreen.V363.SecretId
import Evergreen.V363.SessionIdHash
import Evergreen.V363.Slack
import Evergreen.V363.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId) (Maybe (Evergreen.V363.Id.Id Evergreen.V363.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V363.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V363.Discord.Id Evergreen.V363.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V363.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId
    , guildId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V363.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V363.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.UserId
    , channelId : Evergreen.V363.Discord.Id Evergreen.V363.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V363.Id.Id Evergreen.V363.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V363.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V363.Id.Id Evergreen.V363.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V363.Id.Id Evergreen.V363.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V363.Slack.OAuthCode, Evergreen.V363.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V363.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V363.SecretId.SecretId Evergreen.V363.Id.GamePublicId)


type ChannelSidebarMode
    = ChannelSidebarNotDragging
        { offset : Float
        }
    | ChannelSidebarDragging
        { offset : Float
        , previousOffset : Float
        , time : Effect.Time.Posix
        }
