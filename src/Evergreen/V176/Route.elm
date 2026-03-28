module Evergreen.V176.Route exposing (..)

import Evergreen.V176.Discord
import Evergreen.V176.Id
import Evergreen.V176.Pagination
import Evergreen.V176.SecretId
import Evergreen.V176.SessionIdHash
import Evergreen.V176.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId) (Maybe (Evergreen.V176.Id.Id Evergreen.V176.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V176.SecretId.SecretId Evergreen.V176.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V176.Discord.Id Evergreen.V176.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId
    , guildId : Evergreen.V176.Discord.Id Evergreen.V176.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V176.Discord.Id Evergreen.V176.Discord.UserId
    , channelId : Evergreen.V176.Discord.Id Evergreen.V176.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V176.Id.Id Evergreen.V176.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V176.Id.Id Evergreen.V176.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V176.Id.Id Evergreen.V176.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V176.Id.Id Evergreen.V176.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V176.Slack.OAuthCode, Evergreen.V176.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V176.Discord.UserAuth)
