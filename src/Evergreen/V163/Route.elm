module Evergreen.V163.Route exposing (..)

import Evergreen.V163.Discord
import Evergreen.V163.Id
import Evergreen.V163.Pagination
import Evergreen.V163.SecretId
import Evergreen.V163.SessionIdHash
import Evergreen.V163.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId) (Maybe (Evergreen.V163.Id.Id Evergreen.V163.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V163.SecretId.SecretId Evergreen.V163.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V163.Discord.Id Evergreen.V163.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId
    , guildId : Evergreen.V163.Discord.Id Evergreen.V163.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V163.Discord.Id Evergreen.V163.Discord.UserId
    , channelId : Evergreen.V163.Discord.Id Evergreen.V163.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V163.Id.Id Evergreen.V163.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V163.Id.Id Evergreen.V163.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V163.Id.Id Evergreen.V163.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V163.Id.Id Evergreen.V163.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V163.Slack.OAuthCode, Evergreen.V163.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V163.Discord.UserAuth)
