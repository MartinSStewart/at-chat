module Evergreen.V157.Route exposing (..)

import Evergreen.V157.Discord
import Evergreen.V157.Id
import Evergreen.V157.Pagination
import Evergreen.V157.SecretId
import Evergreen.V157.SessionIdHash
import Evergreen.V157.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId) (Maybe (Evergreen.V157.Id.Id Evergreen.V157.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V157.SecretId.SecretId Evergreen.V157.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V157.Discord.Id Evergreen.V157.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId
    , guildId : Evergreen.V157.Discord.Id Evergreen.V157.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V157.Discord.Id Evergreen.V157.Discord.UserId
    , channelId : Evergreen.V157.Discord.Id Evergreen.V157.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V157.Id.Id Evergreen.V157.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V157.Id.Id Evergreen.V157.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V157.Id.Id Evergreen.V157.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V157.Id.Id Evergreen.V157.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V157.Slack.OAuthCode, Evergreen.V157.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V157.Discord.UserAuth)
