module Evergreen.V136.Route exposing (..)

import Evergreen.V136.Discord
import Evergreen.V136.Discord.Id
import Evergreen.V136.Id
import Evergreen.V136.SecretId
import Evergreen.V136.SessionIdHash
import Evergreen.V136.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId) (Maybe (Evergreen.V136.Id.Id Evergreen.V136.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V136.SecretId.SecretId Evergreen.V136.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId
    , guildId : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.UserId
    , channelId : Evergreen.V136.Discord.Id.Id Evergreen.V136.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V136.Id.Id Evergreen.V136.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V136.Id.Id Evergreen.V136.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V136.Id.Id Evergreen.V136.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V136.Slack.OAuthCode, Evergreen.V136.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V136.Discord.UserAuth)
