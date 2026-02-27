module Evergreen.V122.Route exposing (..)

import Evergreen.V122.Discord
import Evergreen.V122.Discord.Id
import Evergreen.V122.Id
import Evergreen.V122.SecretId
import Evergreen.V122.SessionIdHash
import Evergreen.V122.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId) (Maybe (Evergreen.V122.Id.Id Evergreen.V122.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V122.SecretId.SecretId Evergreen.V122.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
    , guildId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.UserId
    , channelId : Evergreen.V122.Discord.Id.Id Evergreen.V122.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V122.Id.Id Evergreen.V122.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V122.Id.Id Evergreen.V122.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V122.Id.Id Evergreen.V122.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V122.Slack.OAuthCode, Evergreen.V122.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V122.Discord.UserAuth)
