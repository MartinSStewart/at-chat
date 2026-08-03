module Evergreen.V344.Route exposing (..)

import Evergreen.V344.Discord
import Evergreen.V344.DmChannelId
import Evergreen.V344.Id
import Evergreen.V344.Pagination
import Evergreen.V344.SecretId
import Evergreen.V344.SessionIdHash
import Evergreen.V344.Slack
import Evergreen.V344.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId) (Maybe (Evergreen.V344.Id.Id Evergreen.V344.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V344.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V344.Discord.Id Evergreen.V344.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V344.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId
    , guildId : Evergreen.V344.Discord.Id Evergreen.V344.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V344.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V344.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V344.Discord.Id Evergreen.V344.Discord.UserId
    , channelId : Evergreen.V344.Discord.Id Evergreen.V344.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V344.Id.Id Evergreen.V344.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V344.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V344.Id.Id Evergreen.V344.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V344.Id.Id Evergreen.V344.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V344.Slack.OAuthCode, Evergreen.V344.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V344.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V344.SecretId.SecretId Evergreen.V344.Id.GamePublicId)
