module Evergreen.V149.Route exposing (..)

import Evergreen.V149.Discord
import Evergreen.V149.Id
import Evergreen.V149.Pagination
import Evergreen.V149.SecretId
import Evergreen.V149.SessionIdHash
import Evergreen.V149.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId) (Maybe (Evergreen.V149.Id.Id Evergreen.V149.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V149.SecretId.SecretId Evergreen.V149.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V149.Discord.Id Evergreen.V149.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId
    , guildId : Evergreen.V149.Discord.Id Evergreen.V149.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V149.Discord.Id Evergreen.V149.Discord.UserId
    , channelId : Evergreen.V149.Discord.Id Evergreen.V149.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V149.Id.Id Evergreen.V149.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V149.Id.Id Evergreen.V149.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V149.Id.Id Evergreen.V149.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V149.Slack.OAuthCode, Evergreen.V149.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V149.Discord.UserAuth)
