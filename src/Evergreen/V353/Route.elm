module Evergreen.V353.Route exposing (..)

import Evergreen.V353.Discord
import Evergreen.V353.DmChannelId
import Evergreen.V353.Id
import Evergreen.V353.Pagination
import Evergreen.V353.SecretId
import Evergreen.V353.SessionIdHash
import Evergreen.V353.Slack
import Evergreen.V353.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId) (Maybe (Evergreen.V353.Id.Id Evergreen.V353.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V353.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V353.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId
    , guildId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V353.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V353.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId
    , channelId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V353.Id.Id Evergreen.V353.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V353.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V353.Id.Id Evergreen.V353.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V353.Id.Id Evergreen.V353.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V353.Slack.OAuthCode, Evergreen.V353.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V353.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V353.SecretId.SecretId Evergreen.V353.Id.GamePublicId)
