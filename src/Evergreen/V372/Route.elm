module Evergreen.V372.Route exposing (..)

import Effect.Time
import Evergreen.V372.Discord
import Evergreen.V372.DmChannelId
import Evergreen.V372.Id
import Evergreen.V372.Pagination
import Evergreen.V372.SecretId
import Evergreen.V372.SessionIdHash
import Evergreen.V372.Slack
import Evergreen.V372.UserSession


type ShowChannelSettings
    = ShowChannelSettings
    | HideChannelSettings


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)) ShowChannelSettings
    | ViewThreadWithFriends (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId) (Maybe (Evergreen.V372.Id.Id Evergreen.V372.Id.ThreadMessageId)) ShowChannelSettings


type ChannelRoute
    = ChannelRoute (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V372.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.InviteLinkId)


type ChannelsVisibleOnMobile
    = ChannelsHiddenOnMobile
    | ChannelsVisibleOnMobile


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V372.Discord.Id Evergreen.V372.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V372.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId
    , guildId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DmRouteData =
    { channelId : Evergreen.V372.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V372.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.UserId
    , channelId : Evergreen.V372.Discord.Id Evergreen.V372.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V372.Id.Id Evergreen.V372.Id.ChannelMessageId)
    , showMembersTab : ShowChannelSettings
    , tab : Maybe Evergreen.V372.UserSession.ChannelHeaderTab
    , channelsVisible : ChannelsVisibleOnMobile
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V372.Id.Id Evergreen.V372.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V372.Id.Id Evergreen.V372.Id.GuildId) ChannelRoute ChannelsVisibleOnMobile
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V372.Slack.OAuthCode, Evergreen.V372.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V372.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V372.SecretId.SecretId Evergreen.V372.Id.GamePublicId)
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
