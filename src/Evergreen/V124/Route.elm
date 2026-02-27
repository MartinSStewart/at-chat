module Evergreen.V124.Route exposing (..)

import Evergreen.V124.Discord
import Evergreen.V124.Discord.Id
import Evergreen.V124.Id
import Evergreen.V124.SecretId
import Evergreen.V124.SessionIdHash
import Evergreen.V124.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId) (Maybe (Evergreen.V124.Id.Id Evergreen.V124.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V124.SecretId.SecretId Evergreen.V124.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
    , guildId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.UserId
    , channelId : Evergreen.V124.Discord.Id.Id Evergreen.V124.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V124.Id.Id Evergreen.V124.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V124.Id.Id Evergreen.V124.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V124.Slack.OAuthCode, Evergreen.V124.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V124.Discord.UserAuth)
