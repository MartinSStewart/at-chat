module Evergreen.V137.Route exposing (..)

import Evergreen.V137.Discord
import Evergreen.V137.Discord.Id
import Evergreen.V137.Id
import Evergreen.V137.SecretId
import Evergreen.V137.SessionIdHash
import Evergreen.V137.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId) (Maybe (Evergreen.V137.Id.Id Evergreen.V137.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V137.SecretId.SecretId Evergreen.V137.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId
    , guildId : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.UserId
    , channelId : Evergreen.V137.Discord.Id.Id Evergreen.V137.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V137.Id.Id Evergreen.V137.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V137.Id.Id Evergreen.V137.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V137.Id.Id Evergreen.V137.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V137.Slack.OAuthCode, Evergreen.V137.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V137.Discord.UserAuth)
