module Evergreen.V201.Route exposing (..)

import Evergreen.V201.Discord
import Evergreen.V201.Id
import Evergreen.V201.Pagination
import Evergreen.V201.SecretId
import Evergreen.V201.SessionIdHash
import Evergreen.V201.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId) (Maybe (Evergreen.V201.Id.Id Evergreen.V201.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V201.SecretId.SecretId Evergreen.V201.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V201.Discord.Id Evergreen.V201.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId
    , guildId : Evergreen.V201.Discord.Id Evergreen.V201.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V201.Discord.Id Evergreen.V201.Discord.UserId
    , channelId : Evergreen.V201.Discord.Id Evergreen.V201.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V201.Id.Id Evergreen.V201.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V201.Id.Id Evergreen.V201.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V201.Id.Id Evergreen.V201.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V201.Slack.OAuthCode, Evergreen.V201.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V201.Discord.UserAuth)
