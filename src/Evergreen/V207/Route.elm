module Evergreen.V207.Route exposing (..)

import Evergreen.V207.Discord
import Evergreen.V207.Id
import Evergreen.V207.Pagination
import Evergreen.V207.SecretId
import Evergreen.V207.SessionIdHash
import Evergreen.V207.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId) (Maybe (Evergreen.V207.Id.Id Evergreen.V207.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V207.SecretId.SecretId Evergreen.V207.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V207.Discord.Id Evergreen.V207.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId
    , guildId : Evergreen.V207.Discord.Id Evergreen.V207.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V207.Discord.Id Evergreen.V207.Discord.UserId
    , channelId : Evergreen.V207.Discord.Id Evergreen.V207.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V207.Id.Id Evergreen.V207.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V207.Id.Id Evergreen.V207.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V207.Id.Id Evergreen.V207.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V207.Slack.OAuthCode, Evergreen.V207.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V207.Discord.UserAuth)
