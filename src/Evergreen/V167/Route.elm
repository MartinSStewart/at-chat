module Evergreen.V167.Route exposing (..)

import Evergreen.V167.Discord
import Evergreen.V167.Id
import Evergreen.V167.Pagination
import Evergreen.V167.SecretId
import Evergreen.V167.SessionIdHash
import Evergreen.V167.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId) (Maybe (Evergreen.V167.Id.Id Evergreen.V167.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V167.SecretId.SecretId Evergreen.V167.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V167.Discord.Id Evergreen.V167.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId
    , guildId : Evergreen.V167.Discord.Id Evergreen.V167.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V167.Discord.Id Evergreen.V167.Discord.UserId
    , channelId : Evergreen.V167.Discord.Id Evergreen.V167.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V167.Id.Id Evergreen.V167.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V167.Id.Id Evergreen.V167.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V167.Id.Id Evergreen.V167.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V167.Slack.OAuthCode, Evergreen.V167.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V167.Discord.UserAuth)
