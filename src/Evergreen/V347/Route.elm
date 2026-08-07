module Evergreen.V347.Route exposing (..)

import Evergreen.V347.Discord
import Evergreen.V347.DmChannelId
import Evergreen.V347.Id
import Evergreen.V347.Pagination
import Evergreen.V347.SecretId
import Evergreen.V347.SessionIdHash
import Evergreen.V347.Slack
import Evergreen.V347.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId) (Maybe (Evergreen.V347.Id.Id Evergreen.V347.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V347.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V347.SecretId.SecretId Evergreen.V347.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V347.Discord.Id Evergreen.V347.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V347.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId
    , guildId : Evergreen.V347.Discord.Id Evergreen.V347.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V347.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V347.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V347.Discord.Id Evergreen.V347.Discord.UserId
    , channelId : Evergreen.V347.Discord.Id Evergreen.V347.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V347.Id.Id Evergreen.V347.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V347.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V347.Id.Id Evergreen.V347.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V347.Id.Id Evergreen.V347.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V347.Slack.OAuthCode, Evergreen.V347.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V347.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V347.SecretId.SecretId Evergreen.V347.Id.GamePublicId)
