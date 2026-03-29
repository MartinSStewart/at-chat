module Evergreen.V177.Route exposing (..)

import Evergreen.V177.Discord
import Evergreen.V177.Id
import Evergreen.V177.Pagination
import Evergreen.V177.SecretId
import Evergreen.V177.SessionIdHash
import Evergreen.V177.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId) (Maybe (Evergreen.V177.Id.Id Evergreen.V177.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V177.SecretId.SecretId Evergreen.V177.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V177.Discord.Id Evergreen.V177.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId
    , guildId : Evergreen.V177.Discord.Id Evergreen.V177.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V177.Discord.Id Evergreen.V177.Discord.UserId
    , channelId : Evergreen.V177.Discord.Id Evergreen.V177.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V177.Id.Id Evergreen.V177.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V177.Id.Id Evergreen.V177.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V177.Id.Id Evergreen.V177.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V177.Id.Id Evergreen.V177.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V177.Slack.OAuthCode, Evergreen.V177.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V177.Discord.UserAuth)
