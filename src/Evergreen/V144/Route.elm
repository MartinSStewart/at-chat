module Evergreen.V144.Route exposing (..)

import Evergreen.V144.Discord
import Evergreen.V144.Id
import Evergreen.V144.SecretId
import Evergreen.V144.SessionIdHash
import Evergreen.V144.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId) (Maybe (Evergreen.V144.Id.Id Evergreen.V144.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V144.SecretId.SecretId Evergreen.V144.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V144.Discord.Id Evergreen.V144.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId
    , guildId : Evergreen.V144.Discord.Id Evergreen.V144.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V144.Discord.Id Evergreen.V144.Discord.UserId
    , channelId : Evergreen.V144.Discord.Id Evergreen.V144.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V144.Id.Id Evergreen.V144.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V144.Id.Id Evergreen.V144.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V144.Id.Id Evergreen.V144.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V144.Slack.OAuthCode, Evergreen.V144.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V144.Discord.UserAuth)
