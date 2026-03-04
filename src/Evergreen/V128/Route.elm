module Evergreen.V128.Route exposing (..)

import Evergreen.V128.Discord
import Evergreen.V128.Discord.Id
import Evergreen.V128.Id
import Evergreen.V128.SecretId
import Evergreen.V128.SessionIdHash
import Evergreen.V128.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId) (Maybe (Evergreen.V128.Id.Id Evergreen.V128.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V128.SecretId.SecretId Evergreen.V128.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId
    , guildId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.UserId
    , channelId : Evergreen.V128.Discord.Id.Id Evergreen.V128.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V128.Id.Id Evergreen.V128.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V128.Id.Id Evergreen.V128.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V128.Id.Id Evergreen.V128.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V128.Slack.OAuthCode, Evergreen.V128.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V128.Discord.UserAuth)
