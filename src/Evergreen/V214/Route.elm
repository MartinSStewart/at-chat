module Evergreen.V214.Route exposing (..)

import Evergreen.V214.Discord
import Evergreen.V214.Id
import Evergreen.V214.Pagination
import Evergreen.V214.SecretId
import Evergreen.V214.SessionIdHash
import Evergreen.V214.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId) (Maybe (Evergreen.V214.Id.Id Evergreen.V214.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V214.SecretId.SecretId Evergreen.V214.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V214.Discord.Id Evergreen.V214.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId
    , guildId : Evergreen.V214.Discord.Id Evergreen.V214.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V214.Id.Id Evergreen.V214.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V214.Discord.Id Evergreen.V214.Discord.UserId
    , channelId : Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V214.Id.Id Evergreen.V214.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V214.Id.Id Evergreen.V214.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V214.Id.Id Evergreen.V214.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V214.Slack.OAuthCode, Evergreen.V214.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V214.Discord.UserAuth)
