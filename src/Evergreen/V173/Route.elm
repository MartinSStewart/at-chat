module Evergreen.V173.Route exposing (..)

import Evergreen.V173.Discord
import Evergreen.V173.Id
import Evergreen.V173.Pagination
import Evergreen.V173.SecretId
import Evergreen.V173.SessionIdHash
import Evergreen.V173.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId) (Maybe (Evergreen.V173.Id.Id Evergreen.V173.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V173.SecretId.SecretId Evergreen.V173.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V173.Discord.Id Evergreen.V173.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId
    , guildId : Evergreen.V173.Discord.Id Evergreen.V173.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V173.Discord.Id Evergreen.V173.Discord.UserId
    , channelId : Evergreen.V173.Discord.Id Evergreen.V173.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V173.Id.Id Evergreen.V173.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V173.Id.Id Evergreen.V173.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V173.Id.Id Evergreen.V173.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V173.Id.Id Evergreen.V173.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V173.Slack.OAuthCode, Evergreen.V173.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V173.Discord.UserAuth)
