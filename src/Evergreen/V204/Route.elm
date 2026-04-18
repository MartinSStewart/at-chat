module Evergreen.V204.Route exposing (..)

import Evergreen.V204.Discord
import Evergreen.V204.Id
import Evergreen.V204.Pagination
import Evergreen.V204.SecretId
import Evergreen.V204.SessionIdHash
import Evergreen.V204.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId) (Maybe (Evergreen.V204.Id.Id Evergreen.V204.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V204.SecretId.SecretId Evergreen.V204.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V204.Discord.Id Evergreen.V204.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId
    , guildId : Evergreen.V204.Discord.Id Evergreen.V204.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V204.Discord.Id Evergreen.V204.Discord.UserId
    , channelId : Evergreen.V204.Discord.Id Evergreen.V204.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V204.Id.Id Evergreen.V204.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V204.Id.Id Evergreen.V204.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V204.Id.Id Evergreen.V204.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V204.Slack.OAuthCode, Evergreen.V204.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V204.Discord.UserAuth)
