module Evergreen.V349.Route exposing (..)

import Evergreen.V349.Discord
import Evergreen.V349.DmChannelId
import Evergreen.V349.Id
import Evergreen.V349.Pagination
import Evergreen.V349.SecretId
import Evergreen.V349.SessionIdHash
import Evergreen.V349.Slack
import Evergreen.V349.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId) (Maybe (Evergreen.V349.Id.Id Evergreen.V349.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V349.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V349.Discord.Id Evergreen.V349.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V349.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId
    , guildId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V349.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V349.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.UserId
    , channelId : Evergreen.V349.Discord.Id Evergreen.V349.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V349.Id.Id Evergreen.V349.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V349.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V349.Id.Id Evergreen.V349.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V349.Id.Id Evergreen.V349.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V349.Slack.OAuthCode, Evergreen.V349.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V349.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V349.SecretId.SecretId Evergreen.V349.Id.GamePublicId)
