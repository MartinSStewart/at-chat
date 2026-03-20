module Evergreen.V161.Route exposing (..)

import Evergreen.V161.Discord
import Evergreen.V161.Id
import Evergreen.V161.Pagination
import Evergreen.V161.SecretId
import Evergreen.V161.SessionIdHash
import Evergreen.V161.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId) (Maybe (Evergreen.V161.Id.Id Evergreen.V161.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V161.SecretId.SecretId Evergreen.V161.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V161.Discord.Id Evergreen.V161.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId
    , guildId : Evergreen.V161.Discord.Id Evergreen.V161.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V161.Discord.Id Evergreen.V161.Discord.UserId
    , channelId : Evergreen.V161.Discord.Id Evergreen.V161.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V161.Id.Id Evergreen.V161.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V161.Id.Id Evergreen.V161.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V161.Id.Id Evergreen.V161.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V161.Id.Id Evergreen.V161.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V161.Slack.OAuthCode, Evergreen.V161.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V161.Discord.UserAuth)
