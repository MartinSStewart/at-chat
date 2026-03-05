module Evergreen.V135.Route exposing (..)

import Evergreen.V135.Discord
import Evergreen.V135.Discord.Id
import Evergreen.V135.Id
import Evergreen.V135.SecretId
import Evergreen.V135.SessionIdHash
import Evergreen.V135.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId) (Maybe (Evergreen.V135.Id.Id Evergreen.V135.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V135.SecretId.SecretId Evergreen.V135.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId
    , guildId : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.UserId
    , channelId : Evergreen.V135.Discord.Id.Id Evergreen.V135.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V135.Id.Id Evergreen.V135.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V135.Id.Id Evergreen.V135.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V135.Id.Id Evergreen.V135.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V135.Slack.OAuthCode, Evergreen.V135.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V135.Discord.UserAuth)
