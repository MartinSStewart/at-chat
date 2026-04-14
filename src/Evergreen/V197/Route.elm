module Evergreen.V197.Route exposing (..)

import Evergreen.V197.Discord
import Evergreen.V197.Id
import Evergreen.V197.Pagination
import Evergreen.V197.SecretId
import Evergreen.V197.SessionIdHash
import Evergreen.V197.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId) (Maybe (Evergreen.V197.Id.Id Evergreen.V197.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V197.SecretId.SecretId Evergreen.V197.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V197.Discord.Id Evergreen.V197.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId
    , guildId : Evergreen.V197.Discord.Id Evergreen.V197.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V197.Discord.Id Evergreen.V197.Discord.UserId
    , channelId : Evergreen.V197.Discord.Id Evergreen.V197.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V197.Id.Id Evergreen.V197.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V197.Id.Id Evergreen.V197.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V197.Id.Id Evergreen.V197.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V197.Slack.OAuthCode, Evergreen.V197.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V197.Discord.UserAuth)
