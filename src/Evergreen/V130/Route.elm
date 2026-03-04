module Evergreen.V130.Route exposing (..)

import Evergreen.V130.Discord
import Evergreen.V130.Discord.Id
import Evergreen.V130.Id
import Evergreen.V130.SecretId
import Evergreen.V130.SessionIdHash
import Evergreen.V130.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId) (Maybe (Evergreen.V130.Id.Id Evergreen.V130.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V130.SecretId.SecretId Evergreen.V130.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId
    , guildId : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.UserId
    , channelId : Evergreen.V130.Discord.Id.Id Evergreen.V130.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V130.Id.Id Evergreen.V130.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V130.Id.Id Evergreen.V130.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V130.Id.Id Evergreen.V130.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V130.Slack.OAuthCode, Evergreen.V130.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V130.Discord.UserAuth)
