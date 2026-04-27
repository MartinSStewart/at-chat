module Evergreen.V209.Route exposing (..)

import Evergreen.V209.Discord
import Evergreen.V209.Id
import Evergreen.V209.Pagination
import Evergreen.V209.SecretId
import Evergreen.V209.SessionIdHash
import Evergreen.V209.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId) (Maybe (Evergreen.V209.Id.Id Evergreen.V209.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V209.SecretId.SecretId Evergreen.V209.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V209.Discord.Id Evergreen.V209.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId
    , guildId : Evergreen.V209.Discord.Id Evergreen.V209.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V209.Discord.Id Evergreen.V209.Discord.UserId
    , channelId : Evergreen.V209.Discord.Id Evergreen.V209.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V209.Id.Id Evergreen.V209.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V209.Id.Id Evergreen.V209.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V209.Id.Id Evergreen.V209.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V209.Slack.OAuthCode, Evergreen.V209.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V209.Discord.UserAuth)
