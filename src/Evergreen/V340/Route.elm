module Evergreen.V340.Route exposing (..)

import Evergreen.V340.Discord
import Evergreen.V340.DmChannelId
import Evergreen.V340.Id
import Evergreen.V340.Pagination
import Evergreen.V340.SecretId
import Evergreen.V340.SessionIdHash
import Evergreen.V340.Slack
import Evergreen.V340.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId) (Maybe (Evergreen.V340.Id.Id Evergreen.V340.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V340.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V340.Discord.Id Evergreen.V340.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V340.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId
    , guildId : Evergreen.V340.Discord.Id Evergreen.V340.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V340.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V340.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V340.Discord.Id Evergreen.V340.Discord.UserId
    , channelId : Evergreen.V340.Discord.Id Evergreen.V340.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V340.Id.Id Evergreen.V340.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V340.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V340.Id.Id Evergreen.V340.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V340.Id.Id Evergreen.V340.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V340.Slack.OAuthCode, Evergreen.V340.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V340.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V340.SecretId.SecretId Evergreen.V340.Id.GamePublicId)
