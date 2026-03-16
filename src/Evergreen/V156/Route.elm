module Evergreen.V156.Route exposing (..)

import Evergreen.V156.Discord
import Evergreen.V156.Id
import Evergreen.V156.Pagination
import Evergreen.V156.SecretId
import Evergreen.V156.SessionIdHash
import Evergreen.V156.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId) (Maybe (Evergreen.V156.Id.Id Evergreen.V156.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V156.SecretId.SecretId Evergreen.V156.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V156.Discord.Id Evergreen.V156.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId
    , guildId : Evergreen.V156.Discord.Id Evergreen.V156.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V156.Discord.Id Evergreen.V156.Discord.UserId
    , channelId : Evergreen.V156.Discord.Id Evergreen.V156.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V156.Id.Id Evergreen.V156.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V156.Id.Id Evergreen.V156.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V156.Id.Id Evergreen.V156.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V156.Id.Id Evergreen.V156.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V156.Slack.OAuthCode, Evergreen.V156.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V156.Discord.UserAuth)
