module Evergreen.V203.Route exposing (..)

import Evergreen.V203.Discord
import Evergreen.V203.Id
import Evergreen.V203.Pagination
import Evergreen.V203.SecretId
import Evergreen.V203.SessionIdHash
import Evergreen.V203.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId) (Maybe (Evergreen.V203.Id.Id Evergreen.V203.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V203.SecretId.SecretId Evergreen.V203.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V203.Discord.Id Evergreen.V203.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId
    , guildId : Evergreen.V203.Discord.Id Evergreen.V203.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V203.Discord.Id Evergreen.V203.Discord.UserId
    , channelId : Evergreen.V203.Discord.Id Evergreen.V203.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V203.Id.Id Evergreen.V203.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V203.Id.Id Evergreen.V203.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V203.Id.Id Evergreen.V203.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V203.Slack.OAuthCode, Evergreen.V203.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V203.Discord.UserAuth)
