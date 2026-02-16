module Evergreen.V114.Route exposing (..)

import Evergreen.V114.Discord.Id
import Evergreen.V114.Id
import Evergreen.V114.SecretId
import Evergreen.V114.SessionIdHash
import Evergreen.V114.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId) (Maybe (Evergreen.V114.Id.Id Evergreen.V114.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V114.SecretId.SecretId Evergreen.V114.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId
    , guildId : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.UserId
    , channelId : Evergreen.V114.Discord.Id.Id Evergreen.V114.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V114.Id.Id Evergreen.V114.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V114.Id.Id Evergreen.V114.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V114.Slack.OAuthCode, Evergreen.V114.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
