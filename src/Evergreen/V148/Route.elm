module Evergreen.V148.Route exposing (..)

import Evergreen.V148.Discord
import Evergreen.V148.Id
import Evergreen.V148.Pagination
import Evergreen.V148.SecretId
import Evergreen.V148.SessionIdHash
import Evergreen.V148.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId) (Maybe (Evergreen.V148.Id.Id Evergreen.V148.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V148.SecretId.SecretId Evergreen.V148.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V148.Discord.Id Evergreen.V148.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId
    , guildId : Evergreen.V148.Discord.Id Evergreen.V148.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V148.Discord.Id Evergreen.V148.Discord.UserId
    , channelId : Evergreen.V148.Discord.Id Evergreen.V148.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V148.Id.Id Evergreen.V148.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V148.Id.Id Evergreen.V148.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V148.Id.Id Evergreen.V148.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V148.Id.Id Evergreen.V148.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V148.Slack.OAuthCode, Evergreen.V148.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V148.Discord.UserAuth)
