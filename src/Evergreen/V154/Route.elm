module Evergreen.V154.Route exposing (..)

import Evergreen.V154.Discord
import Evergreen.V154.Id
import Evergreen.V154.Pagination
import Evergreen.V154.SecretId
import Evergreen.V154.SessionIdHash
import Evergreen.V154.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId) (Maybe (Evergreen.V154.Id.Id Evergreen.V154.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V154.SecretId.SecretId Evergreen.V154.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V154.Discord.Id Evergreen.V154.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId
    , guildId : Evergreen.V154.Discord.Id Evergreen.V154.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V154.Discord.Id Evergreen.V154.Discord.UserId
    , channelId : Evergreen.V154.Discord.Id Evergreen.V154.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V154.Id.Id Evergreen.V154.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V154.Id.Id Evergreen.V154.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V154.Id.Id Evergreen.V154.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V154.Id.Id Evergreen.V154.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V154.Slack.OAuthCode, Evergreen.V154.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V154.Discord.UserAuth)
