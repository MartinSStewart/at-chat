module Evergreen.V199.Route exposing (..)

import Evergreen.V199.Discord
import Evergreen.V199.Id
import Evergreen.V199.Pagination
import Evergreen.V199.SecretId
import Evergreen.V199.SessionIdHash
import Evergreen.V199.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId) (Maybe (Evergreen.V199.Id.Id Evergreen.V199.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V199.SecretId.SecretId Evergreen.V199.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V199.Discord.Id Evergreen.V199.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId
    , guildId : Evergreen.V199.Discord.Id Evergreen.V199.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V199.Discord.Id Evergreen.V199.Discord.UserId
    , channelId : Evergreen.V199.Discord.Id Evergreen.V199.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V199.Id.Id Evergreen.V199.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V199.Id.Id Evergreen.V199.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V199.Id.Id Evergreen.V199.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V199.Slack.OAuthCode, Evergreen.V199.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V199.Discord.UserAuth)
