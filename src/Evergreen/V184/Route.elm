module Evergreen.V184.Route exposing (..)

import Evergreen.V184.Discord
import Evergreen.V184.Id
import Evergreen.V184.Pagination
import Evergreen.V184.SecretId
import Evergreen.V184.SessionIdHash
import Evergreen.V184.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId) (Maybe (Evergreen.V184.Id.Id Evergreen.V184.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V184.SecretId.SecretId Evergreen.V184.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V184.Discord.Id Evergreen.V184.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId
    , guildId : Evergreen.V184.Discord.Id Evergreen.V184.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V184.Discord.Id Evergreen.V184.Discord.UserId
    , channelId : Evergreen.V184.Discord.Id Evergreen.V184.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V184.Id.Id Evergreen.V184.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V184.Id.Id Evergreen.V184.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V184.Id.Id Evergreen.V184.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V184.Slack.OAuthCode, Evergreen.V184.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V184.Discord.UserAuth)
