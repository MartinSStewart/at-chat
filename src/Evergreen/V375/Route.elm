module Evergreen.V375.Route exposing (..)

import Effect.Time
import Evergreen.V375.Discord
import Evergreen.V375.DmChannelId
import Evergreen.V375.Id
import Evergreen.V375.Pagination
import Evergreen.V375.SecretId
import Evergreen.V375.SessionIdHash
import Evergreen.V375.Slack
import Evergreen.V375.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId) (Maybe (Evergreen.V375.Id.Id Evergreen.V375.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V375.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V375.Discord.Id Evergreen.V375.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V375.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId
    , guildId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V375.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V375.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.UserId
    , channelId : Evergreen.V375.Discord.Id Evergreen.V375.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V375.Id.Id Evergreen.V375.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V375.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V375.Id.Id Evergreen.V375.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V375.Id.Id Evergreen.V375.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V375.Slack.OAuthCode, Evergreen.V375.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V375.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V375.SecretId.SecretId Evergreen.V375.Id.GamePublicId)
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
