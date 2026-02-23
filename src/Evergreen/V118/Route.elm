module Evergreen.V118.Route exposing (..)

import Evergreen.V118.Discord
import Evergreen.V118.Discord.Id
import Evergreen.V118.Id
import Evergreen.V118.SecretId
import Evergreen.V118.SessionIdHash
import Evergreen.V118.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId) (Maybe (Evergreen.V118.Id.Id Evergreen.V118.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V118.SecretId.SecretId Evergreen.V118.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId
    , guildId : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.UserId
    , channelId : Evergreen.V118.Discord.Id.Id Evergreen.V118.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V118.Id.Id Evergreen.V118.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V118.Id.Id Evergreen.V118.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V118.Id.Id Evergreen.V118.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V118.Slack.OAuthCode, Evergreen.V118.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V118.Discord.UserAuth)
