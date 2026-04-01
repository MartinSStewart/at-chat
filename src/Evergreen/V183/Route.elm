module Evergreen.V183.Route exposing (..)

import Evergreen.V183.Discord
import Evergreen.V183.Id
import Evergreen.V183.Pagination
import Evergreen.V183.SecretId
import Evergreen.V183.SessionIdHash
import Evergreen.V183.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId) (Maybe (Evergreen.V183.Id.Id Evergreen.V183.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V183.SecretId.SecretId Evergreen.V183.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V183.Discord.Id Evergreen.V183.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId
    , guildId : Evergreen.V183.Discord.Id Evergreen.V183.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V183.Discord.Id Evergreen.V183.Discord.UserId
    , channelId : Evergreen.V183.Discord.Id Evergreen.V183.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V183.Id.Id Evergreen.V183.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V183.Id.Id Evergreen.V183.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V183.Id.Id Evergreen.V183.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V183.Slack.OAuthCode, Evergreen.V183.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V183.Discord.UserAuth)
