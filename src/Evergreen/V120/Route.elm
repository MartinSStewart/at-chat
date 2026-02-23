module Evergreen.V120.Route exposing (..)

import Evergreen.V120.Discord
import Evergreen.V120.Discord.Id
import Evergreen.V120.Id
import Evergreen.V120.SecretId
import Evergreen.V120.SessionIdHash
import Evergreen.V120.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId) (Maybe (Evergreen.V120.Id.Id Evergreen.V120.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V120.SecretId.SecretId Evergreen.V120.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId
    , guildId : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.UserId
    , channelId : Evergreen.V120.Discord.Id.Id Evergreen.V120.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V120.Id.Id Evergreen.V120.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V120.Id.Id Evergreen.V120.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V120.Id.Id Evergreen.V120.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V120.Slack.OAuthCode, Evergreen.V120.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V120.Discord.UserAuth)
