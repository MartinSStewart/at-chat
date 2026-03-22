module Evergreen.V166.Route exposing (..)

import Evergreen.V166.Discord
import Evergreen.V166.Id
import Evergreen.V166.Pagination
import Evergreen.V166.SecretId
import Evergreen.V166.SessionIdHash
import Evergreen.V166.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId) (Maybe (Evergreen.V166.Id.Id Evergreen.V166.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V166.SecretId.SecretId Evergreen.V166.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V166.Discord.Id Evergreen.V166.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId
    , guildId : Evergreen.V166.Discord.Id Evergreen.V166.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V166.Discord.Id Evergreen.V166.Discord.UserId
    , channelId : Evergreen.V166.Discord.Id Evergreen.V166.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V166.Id.Id Evergreen.V166.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V166.Id.Id Evergreen.V166.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V166.Id.Id Evergreen.V166.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V166.Slack.OAuthCode, Evergreen.V166.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V166.Discord.UserAuth)
