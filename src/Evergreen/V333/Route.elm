module Evergreen.V333.Route exposing (..)

import Evergreen.V333.Discord
import Evergreen.V333.DmChannelId
import Evergreen.V333.Id
import Evergreen.V333.Pagination
import Evergreen.V333.SecretId
import Evergreen.V333.SessionIdHash
import Evergreen.V333.Slack
import Evergreen.V333.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId) (Maybe (Evergreen.V333.Id.Id Evergreen.V333.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V333.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V333.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V333.Discord.Id Evergreen.V333.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId
    , guildId : Evergreen.V333.Discord.Id Evergreen.V333.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V333.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V333.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V333.Discord.Id Evergreen.V333.Discord.UserId
    , channelId : Evergreen.V333.Discord.Id Evergreen.V333.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V333.Id.Id Evergreen.V333.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V333.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V333.Id.Id Evergreen.V333.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V333.Id.Id Evergreen.V333.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V333.Slack.OAuthCode, Evergreen.V333.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V333.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V333.SecretId.SecretId Evergreen.V333.Id.GamePublicId)
