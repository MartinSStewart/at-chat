module Evergreen.V116.Route exposing (..)

import Evergreen.V116.Discord.Id
import Evergreen.V116.Id
import Evergreen.V116.SecretId
import Evergreen.V116.SessionIdHash
import Evergreen.V116.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId) (Maybe (Evergreen.V116.Id.Id Evergreen.V116.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V116.SecretId.SecretId Evergreen.V116.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId
    , guildId : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.UserId
    , channelId : Evergreen.V116.Discord.Id.Id Evergreen.V116.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V116.Id.Id Evergreen.V116.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V116.Id.Id Evergreen.V116.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V116.Slack.OAuthCode, Evergreen.V116.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
