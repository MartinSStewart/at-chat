module Evergreen.V112.Route exposing (..)

import Evergreen.V112.Discord.Id
import Evergreen.V112.Id
import Evergreen.V112.SecretId
import Evergreen.V112.SessionIdHash
import Evergreen.V112.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId) (Maybe (Evergreen.V112.Id.Id Evergreen.V112.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V112.SecretId.SecretId Evergreen.V112.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId
    , guildId : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.UserId
    , channelId : Evergreen.V112.Discord.Id.Id Evergreen.V112.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V112.Id.Id Evergreen.V112.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V112.Id.Id Evergreen.V112.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V112.Slack.OAuthCode, Evergreen.V112.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
