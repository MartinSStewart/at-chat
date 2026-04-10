module Evergreen.V192.Route exposing (..)

import Evergreen.V192.Discord
import Evergreen.V192.Id
import Evergreen.V192.Pagination
import Evergreen.V192.SecretId
import Evergreen.V192.SessionIdHash
import Evergreen.V192.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId) (Maybe (Evergreen.V192.Id.Id Evergreen.V192.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V192.SecretId.SecretId Evergreen.V192.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V192.Discord.Id Evergreen.V192.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId
    , guildId : Evergreen.V192.Discord.Id Evergreen.V192.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V192.Discord.Id Evergreen.V192.Discord.UserId
    , channelId : Evergreen.V192.Discord.Id Evergreen.V192.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V192.Id.Id Evergreen.V192.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V192.Id.Id Evergreen.V192.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V192.Id.Id Evergreen.V192.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V192.Slack.OAuthCode, Evergreen.V192.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V192.Discord.UserAuth)
