module Evergreen.V193.Route exposing (..)

import Evergreen.V193.Discord
import Evergreen.V193.Id
import Evergreen.V193.Pagination
import Evergreen.V193.SecretId
import Evergreen.V193.SessionIdHash
import Evergreen.V193.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId) (Maybe (Evergreen.V193.Id.Id Evergreen.V193.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V193.SecretId.SecretId Evergreen.V193.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V193.Discord.Id Evergreen.V193.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId
    , guildId : Evergreen.V193.Discord.Id Evergreen.V193.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V193.Discord.Id Evergreen.V193.Discord.UserId
    , channelId : Evergreen.V193.Discord.Id Evergreen.V193.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V193.Id.Id Evergreen.V193.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V193.Id.Id Evergreen.V193.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V193.Id.Id Evergreen.V193.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V193.Slack.OAuthCode, Evergreen.V193.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V193.Discord.UserAuth)
