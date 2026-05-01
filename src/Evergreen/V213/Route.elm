module Evergreen.V213.Route exposing (..)

import Evergreen.V213.Discord
import Evergreen.V213.Id
import Evergreen.V213.Pagination
import Evergreen.V213.SecretId
import Evergreen.V213.SessionIdHash
import Evergreen.V213.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId) (Maybe (Evergreen.V213.Id.Id Evergreen.V213.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V213.SecretId.SecretId Evergreen.V213.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V213.Discord.Id Evergreen.V213.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId
    , guildId : Evergreen.V213.Discord.Id Evergreen.V213.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V213.Discord.Id Evergreen.V213.Discord.UserId
    , channelId : Evergreen.V213.Discord.Id Evergreen.V213.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V213.Id.Id Evergreen.V213.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V213.Id.Id Evergreen.V213.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V213.Id.Id Evergreen.V213.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V213.Slack.OAuthCode, Evergreen.V213.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V213.Discord.UserAuth)
