module Evergreen.V211.Route exposing (..)

import Evergreen.V211.Discord
import Evergreen.V211.Id
import Evergreen.V211.Pagination
import Evergreen.V211.SecretId
import Evergreen.V211.SessionIdHash
import Evergreen.V211.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId) (Maybe (Evergreen.V211.Id.Id Evergreen.V211.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V211.SecretId.SecretId Evergreen.V211.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V211.Discord.Id Evergreen.V211.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId
    , guildId : Evergreen.V211.Discord.Id Evergreen.V211.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V211.Discord.Id Evergreen.V211.Discord.UserId
    , channelId : Evergreen.V211.Discord.Id Evergreen.V211.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V211.Id.Id Evergreen.V211.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V211.Id.Id Evergreen.V211.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V211.Id.Id Evergreen.V211.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V211.Slack.OAuthCode, Evergreen.V211.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V211.Discord.UserAuth)
