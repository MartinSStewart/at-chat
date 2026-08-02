module Evergreen.V343.Route exposing (..)

import Evergreen.V343.Discord
import Evergreen.V343.DmChannelId
import Evergreen.V343.Id
import Evergreen.V343.Pagination
import Evergreen.V343.SecretId
import Evergreen.V343.SessionIdHash
import Evergreen.V343.Slack
import Evergreen.V343.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId) (Maybe (Evergreen.V343.Id.Id Evergreen.V343.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V343.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V343.Discord.Id Evergreen.V343.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V343.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId
    , guildId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V343.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V343.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.UserId
    , channelId : Evergreen.V343.Discord.Id Evergreen.V343.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V343.Id.Id Evergreen.V343.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V343.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V343.Id.Id Evergreen.V343.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V343.Id.Id Evergreen.V343.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V343.Slack.OAuthCode, Evergreen.V343.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V343.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V343.SecretId.SecretId Evergreen.V343.Id.GamePublicId)
