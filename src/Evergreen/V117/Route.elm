module Evergreen.V117.Route exposing (..)

import Evergreen.V117.Discord
import Evergreen.V117.Discord.Id
import Evergreen.V117.Id
import Evergreen.V117.SecretId
import Evergreen.V117.SessionIdHash
import Evergreen.V117.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId) (Maybe (Evergreen.V117.Id.Id Evergreen.V117.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V117.SecretId.SecretId Evergreen.V117.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId
    , guildId : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.UserId
    , channelId : Evergreen.V117.Discord.Id.Id Evergreen.V117.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V117.Id.Id Evergreen.V117.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V117.Id.Id Evergreen.V117.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V117.Id.Id Evergreen.V117.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V117.Slack.OAuthCode, Evergreen.V117.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result () Evergreen.V117.Discord.UserAuth)
