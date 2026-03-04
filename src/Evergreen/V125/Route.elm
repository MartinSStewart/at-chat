module Evergreen.V125.Route exposing (..)

import Evergreen.V125.Discord
import Evergreen.V125.Discord.Id
import Evergreen.V125.Id
import Evergreen.V125.SecretId
import Evergreen.V125.SessionIdHash
import Evergreen.V125.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId) (Maybe (Evergreen.V125.Id.Id Evergreen.V125.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V125.SecretId.SecretId Evergreen.V125.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId
    , guildId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.UserId
    , channelId : Evergreen.V125.Discord.Id.Id Evergreen.V125.Discord.Id.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V125.Id.Id Evergreen.V125.Id.ChannelMessageId)
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
    | GuildRoute (Evergreen.V125.Id.Id Evergreen.V125.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V125.Slack.OAuthCode, Evergreen.V125.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V125.Discord.UserAuth)
