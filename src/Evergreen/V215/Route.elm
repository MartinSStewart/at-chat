module Evergreen.V215.Route exposing (..)

import Evergreen.V215.Discord
import Evergreen.V215.Id
import Evergreen.V215.Pagination
import Evergreen.V215.SecretId
import Evergreen.V215.SessionIdHash
import Evergreen.V215.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId) (Maybe (Evergreen.V215.Id.Id Evergreen.V215.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V215.SecretId.SecretId Evergreen.V215.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V215.Discord.Id Evergreen.V215.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId
    , guildId : Evergreen.V215.Discord.Id Evergreen.V215.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V215.Discord.Id Evergreen.V215.Discord.UserId
    , channelId : Evergreen.V215.Discord.Id Evergreen.V215.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V215.Id.Id Evergreen.V215.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V215.Id.Id Evergreen.V215.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V215.Id.Id Evergreen.V215.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | GoRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V215.Slack.OAuthCode, Evergreen.V215.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V215.Discord.UserAuth)
