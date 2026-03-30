module Evergreen.V179.Route exposing (..)

import Evergreen.V179.Discord
import Evergreen.V179.Id
import Evergreen.V179.Pagination
import Evergreen.V179.SecretId
import Evergreen.V179.SessionIdHash
import Evergreen.V179.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId) (Maybe (Evergreen.V179.Id.Id Evergreen.V179.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V179.SecretId.SecretId Evergreen.V179.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V179.Discord.Id Evergreen.V179.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId
    , guildId : Evergreen.V179.Discord.Id Evergreen.V179.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V179.Discord.Id Evergreen.V179.Discord.UserId
    , channelId : Evergreen.V179.Discord.Id Evergreen.V179.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V179.Id.Id Evergreen.V179.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V179.Id.Id Evergreen.V179.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V179.Id.Id Evergreen.V179.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V179.Id.Id Evergreen.V179.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V179.Slack.OAuthCode, Evergreen.V179.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V179.Discord.UserAuth)
