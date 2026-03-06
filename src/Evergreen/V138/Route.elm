module Evergreen.V138.Route exposing (..)

import Evergreen.V138.Discord
import Evergreen.V138.Discord.Id
import Evergreen.V138.Id
import Evergreen.V138.SecretId
import Evergreen.V138.SessionIdHash
import Evergreen.V138.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId) (Maybe (Evergreen.V138.Id.Id Evergreen.V138.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V138.SecretId.SecretId Evergreen.V138.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId
    , guildId : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.UserId
    , channelId : Evergreen.V138.Discord.Id.Id Evergreen.V138.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V138.Id.Id Evergreen.V138.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V138.Id.Id Evergreen.V138.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V138.Id.Id Evergreen.V138.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V138.Slack.OAuthCode, Evergreen.V138.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V138.Discord.UserAuth)
