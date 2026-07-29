module Evergreen.V339.Route exposing (..)

import Evergreen.V339.Discord
import Evergreen.V339.DmChannelId
import Evergreen.V339.Id
import Evergreen.V339.Pagination
import Evergreen.V339.SecretId
import Evergreen.V339.SessionIdHash
import Evergreen.V339.Slack
import Evergreen.V339.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId) (Maybe (Evergreen.V339.Id.Id Evergreen.V339.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V339.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V339.Discord.Id Evergreen.V339.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V339.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId
    , guildId : Evergreen.V339.Discord.Id Evergreen.V339.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V339.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V339.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V339.Discord.Id Evergreen.V339.Discord.UserId
    , channelId : Evergreen.V339.Discord.Id Evergreen.V339.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V339.Id.Id Evergreen.V339.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V339.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V339.Id.Id Evergreen.V339.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V339.Id.Id Evergreen.V339.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V339.Slack.OAuthCode, Evergreen.V339.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V339.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V339.SecretId.SecretId Evergreen.V339.Id.GamePublicId)
