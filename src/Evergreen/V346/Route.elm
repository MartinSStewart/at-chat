module Evergreen.V346.Route exposing (..)

import Evergreen.V346.Discord
import Evergreen.V346.DmChannelId
import Evergreen.V346.Id
import Evergreen.V346.Pagination
import Evergreen.V346.SecretId
import Evergreen.V346.SessionIdHash
import Evergreen.V346.Slack
import Evergreen.V346.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId) (Maybe (Evergreen.V346.Id.Id Evergreen.V346.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V346.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V346.Discord.Id Evergreen.V346.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V346.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId
    , guildId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V346.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V346.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.UserId
    , channelId : Evergreen.V346.Discord.Id Evergreen.V346.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V346.Id.Id Evergreen.V346.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V346.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V346.Id.Id Evergreen.V346.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V346.Id.Id Evergreen.V346.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V346.Slack.OAuthCode, Evergreen.V346.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V346.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V346.SecretId.SecretId Evergreen.V346.Id.GamePublicId)
