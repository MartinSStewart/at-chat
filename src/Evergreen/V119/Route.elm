module Evergreen.V119.Route exposing (..)

import Evergreen.V119.Discord
import Evergreen.V119.Discord.Id
import Evergreen.V119.Id
import Evergreen.V119.SecretId
import Evergreen.V119.SessionIdHash
import Evergreen.V119.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId) (Maybe (Evergreen.V119.Id.Id Evergreen.V119.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V119.SecretId.SecretId Evergreen.V119.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId
    , guildId : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.UserId
    , channelId : Evergreen.V119.Discord.Id.Id Evergreen.V119.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V119.Id.Id Evergreen.V119.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V119.Id.Id Evergreen.V119.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V119.Id.Id Evergreen.V119.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V119.Slack.OAuthCode, Evergreen.V119.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V119.Discord.UserAuth)
