module Evergreen.V342.Route exposing (..)

import Evergreen.V342.Discord
import Evergreen.V342.DmChannelId
import Evergreen.V342.Id
import Evergreen.V342.Pagination
import Evergreen.V342.SecretId
import Evergreen.V342.SessionIdHash
import Evergreen.V342.Slack
import Evergreen.V342.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId) (Maybe (Evergreen.V342.Id.Id Evergreen.V342.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V342.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V342.Discord.Id Evergreen.V342.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V342.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId
    , guildId : Evergreen.V342.Discord.Id Evergreen.V342.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V342.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V342.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V342.Discord.Id Evergreen.V342.Discord.UserId
    , channelId : Evergreen.V342.Discord.Id Evergreen.V342.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V342.Id.Id Evergreen.V342.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V342.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V342.Id.Id Evergreen.V342.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V342.Id.Id Evergreen.V342.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V342.Slack.OAuthCode, Evergreen.V342.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V342.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V342.SecretId.SecretId Evergreen.V342.Id.GamePublicId)
