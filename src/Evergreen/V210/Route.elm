module Evergreen.V210.Route exposing (..)

import Evergreen.V210.Discord
import Evergreen.V210.Id
import Evergreen.V210.Pagination
import Evergreen.V210.SecretId
import Evergreen.V210.SessionIdHash
import Evergreen.V210.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId) (Maybe (Evergreen.V210.Id.Id Evergreen.V210.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V210.SecretId.SecretId Evergreen.V210.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V210.Discord.Id Evergreen.V210.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId
    , guildId : Evergreen.V210.Discord.Id Evergreen.V210.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V210.Discord.Id Evergreen.V210.Discord.UserId
    , channelId : Evergreen.V210.Discord.Id Evergreen.V210.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V210.Id.Id Evergreen.V210.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V210.Id.Id Evergreen.V210.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V210.Id.Id Evergreen.V210.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V210.Slack.OAuthCode, Evergreen.V210.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V210.Discord.UserAuth)
