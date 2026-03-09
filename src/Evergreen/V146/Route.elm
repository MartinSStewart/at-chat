module Evergreen.V146.Route exposing (..)

import Evergreen.V146.Discord
import Evergreen.V146.Id
import Evergreen.V146.SecretId
import Evergreen.V146.SessionIdHash
import Evergreen.V146.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId) (Maybe (Evergreen.V146.Id.Id Evergreen.V146.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V146.SecretId.SecretId Evergreen.V146.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V146.Discord.Id Evergreen.V146.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId
    , guildId : Evergreen.V146.Discord.Id Evergreen.V146.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V146.Discord.Id Evergreen.V146.Discord.UserId
    , channelId : Evergreen.V146.Discord.Id Evergreen.V146.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V146.Id.Id Evergreen.V146.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V146.Id.Id Evergreen.V146.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V146.Id.Id Evergreen.V146.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V146.Slack.OAuthCode, Evergreen.V146.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V146.Discord.UserAuth)
