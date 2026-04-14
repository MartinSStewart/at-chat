module Evergreen.V196.Route exposing (..)

import Evergreen.V196.Discord
import Evergreen.V196.Id
import Evergreen.V196.Pagination
import Evergreen.V196.SecretId
import Evergreen.V196.SessionIdHash
import Evergreen.V196.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId) (Maybe (Evergreen.V196.Id.Id Evergreen.V196.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V196.SecretId.SecretId Evergreen.V196.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V196.Discord.Id Evergreen.V196.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId
    , guildId : Evergreen.V196.Discord.Id Evergreen.V196.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V196.Discord.Id Evergreen.V196.Discord.UserId
    , channelId : Evergreen.V196.Discord.Id Evergreen.V196.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V196.Id.Id Evergreen.V196.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V196.Id.Id Evergreen.V196.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V196.Id.Id Evergreen.V196.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V196.Slack.OAuthCode, Evergreen.V196.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V196.Discord.UserAuth)
