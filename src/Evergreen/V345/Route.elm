module Evergreen.V345.Route exposing (..)

import Evergreen.V345.Discord
import Evergreen.V345.DmChannelId
import Evergreen.V345.Id
import Evergreen.V345.Pagination
import Evergreen.V345.SecretId
import Evergreen.V345.SessionIdHash
import Evergreen.V345.Slack
import Evergreen.V345.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId) (Maybe (Evergreen.V345.Id.Id Evergreen.V345.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V345.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V345.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId
    , guildId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V345.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V345.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId
    , channelId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V345.Id.Id Evergreen.V345.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V345.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V345.Id.Id Evergreen.V345.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V345.Id.Id Evergreen.V345.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V345.Slack.OAuthCode, Evergreen.V345.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V345.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V345.SecretId.SecretId Evergreen.V345.Id.GamePublicId)
