module Evergreen.V115.Route exposing (..)

import Evergreen.V115.Discord.Id
import Evergreen.V115.Id
import Evergreen.V115.SecretId
import Evergreen.V115.SessionIdHash
import Evergreen.V115.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId) (Maybe (Evergreen.V115.Id.Id Evergreen.V115.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V115.SecretId.SecretId Evergreen.V115.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
    , guildId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.UserId
    , channelId : Evergreen.V115.Discord.Id.Id Evergreen.V115.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V115.Id.Id Evergreen.V115.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V115.Id.Id Evergreen.V115.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V115.Slack.OAuthCode, Evergreen.V115.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
