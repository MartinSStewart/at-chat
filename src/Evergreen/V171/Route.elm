module Evergreen.V171.Route exposing (..)

import Evergreen.V171.Discord
import Evergreen.V171.Id
import Evergreen.V171.Pagination
import Evergreen.V171.SecretId
import Evergreen.V171.SessionIdHash
import Evergreen.V171.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId) (Maybe (Evergreen.V171.Id.Id Evergreen.V171.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V171.SecretId.SecretId Evergreen.V171.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V171.Discord.Id Evergreen.V171.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId
    , guildId : Evergreen.V171.Discord.Id Evergreen.V171.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V171.Discord.Id Evergreen.V171.Discord.UserId
    , channelId : Evergreen.V171.Discord.Id Evergreen.V171.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V171.Id.Id Evergreen.V171.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V171.Id.Id Evergreen.V171.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V171.Id.Id Evergreen.V171.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V171.Id.Id Evergreen.V171.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V171.Slack.OAuthCode, Evergreen.V171.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V171.Discord.UserAuth)
