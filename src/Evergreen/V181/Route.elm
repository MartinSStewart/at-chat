module Evergreen.V181.Route exposing (..)

import Evergreen.V181.Discord
import Evergreen.V181.Id
import Evergreen.V181.Pagination
import Evergreen.V181.SecretId
import Evergreen.V181.SessionIdHash
import Evergreen.V181.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId) (Maybe (Evergreen.V181.Id.Id Evergreen.V181.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V181.SecretId.SecretId Evergreen.V181.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V181.Discord.Id Evergreen.V181.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId
    , guildId : Evergreen.V181.Discord.Id Evergreen.V181.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V181.Discord.Id Evergreen.V181.Discord.UserId
    , channelId : Evergreen.V181.Discord.Id Evergreen.V181.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V181.Id.Id Evergreen.V181.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V181.Id.Id Evergreen.V181.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V181.Id.Id Evergreen.V181.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V181.Slack.OAuthCode, Evergreen.V181.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V181.Discord.UserAuth)
