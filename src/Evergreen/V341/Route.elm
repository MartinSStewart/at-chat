module Evergreen.V341.Route exposing (..)

import Evergreen.V341.Discord
import Evergreen.V341.DmChannelId
import Evergreen.V341.Id
import Evergreen.V341.Pagination
import Evergreen.V341.SecretId
import Evergreen.V341.SessionIdHash
import Evergreen.V341.Slack
import Evergreen.V341.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Maybe (Evergreen.V341.Id.Id Evergreen.V341.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V341.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V341.Discord.Id Evergreen.V341.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V341.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId
    , guildId : Evergreen.V341.Discord.Id Evergreen.V341.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V341.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V341.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V341.Discord.Id Evergreen.V341.Discord.UserId
    , channelId : Evergreen.V341.Discord.Id Evergreen.V341.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V341.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V341.Id.Id Evergreen.V341.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V341.Id.Id Evergreen.V341.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V341.Slack.OAuthCode, Evergreen.V341.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V341.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.GamePublicId)
