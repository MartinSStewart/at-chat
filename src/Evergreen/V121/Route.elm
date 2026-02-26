module Evergreen.V121.Route exposing (..)

import Evergreen.V121.Discord
import Evergreen.V121.Discord.Id
import Evergreen.V121.Id
import Evergreen.V121.SecretId
import Evergreen.V121.SessionIdHash
import Evergreen.V121.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId) (Maybe (Evergreen.V121.Id.Id Evergreen.V121.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V121.SecretId.SecretId Evergreen.V121.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId
    , guildId : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.UserId
    , channelId : Evergreen.V121.Discord.Id.Id Evergreen.V121.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V121.Id.Id Evergreen.V121.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V121.Id.Id Evergreen.V121.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V121.Id.Id Evergreen.V121.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V121.Slack.OAuthCode, Evergreen.V121.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V121.Discord.UserAuth)
