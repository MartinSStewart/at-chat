module Evergreen.V182.Route exposing (..)

import Evergreen.V182.Discord
import Evergreen.V182.Id
import Evergreen.V182.Pagination
import Evergreen.V182.SecretId
import Evergreen.V182.SessionIdHash
import Evergreen.V182.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId) (Maybe (Evergreen.V182.Id.Id Evergreen.V182.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V182.SecretId.SecretId Evergreen.V182.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V182.Discord.Id Evergreen.V182.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId
    , guildId : Evergreen.V182.Discord.Id Evergreen.V182.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V182.Discord.Id Evergreen.V182.Discord.UserId
    , channelId : Evergreen.V182.Discord.Id Evergreen.V182.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V182.Id.Id Evergreen.V182.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V182.Id.Id Evergreen.V182.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V182.Id.Id Evergreen.V182.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V182.Slack.OAuthCode, Evergreen.V182.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V182.Discord.UserAuth)
