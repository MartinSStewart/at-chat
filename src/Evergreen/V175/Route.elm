module Evergreen.V175.Route exposing (..)

import Evergreen.V175.Discord
import Evergreen.V175.Id
import Evergreen.V175.Pagination
import Evergreen.V175.SecretId
import Evergreen.V175.SessionIdHash
import Evergreen.V175.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId) (Maybe (Evergreen.V175.Id.Id Evergreen.V175.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V175.SecretId.SecretId Evergreen.V175.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V175.Discord.Id Evergreen.V175.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId
    , guildId : Evergreen.V175.Discord.Id Evergreen.V175.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V175.Discord.Id Evergreen.V175.Discord.UserId
    , channelId : Evergreen.V175.Discord.Id Evergreen.V175.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V175.Id.Id Evergreen.V175.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V175.Id.Id Evergreen.V175.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V175.Id.Id Evergreen.V175.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V175.Id.Id Evergreen.V175.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V175.Slack.OAuthCode, Evergreen.V175.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V175.Discord.UserAuth)
