module Evergreen.V134.Route exposing (..)

import Evergreen.V134.Discord
import Evergreen.V134.Discord.Id
import Evergreen.V134.Id
import Evergreen.V134.SecretId
import Evergreen.V134.SessionIdHash
import Evergreen.V134.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId) (Maybe (Evergreen.V134.Id.Id Evergreen.V134.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V134.SecretId.SecretId Evergreen.V134.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId
    , guildId : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.UserId
    , channelId : Evergreen.V134.Discord.Id.Id Evergreen.V134.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V134.Id.Id Evergreen.V134.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V134.Id.Id Evergreen.V134.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V134.Slack.OAuthCode, Evergreen.V134.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V134.Discord.UserAuth)
