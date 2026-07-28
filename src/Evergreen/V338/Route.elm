module Evergreen.V338.Route exposing (..)

import Evergreen.V338.Discord
import Evergreen.V338.DmChannelId
import Evergreen.V338.Id
import Evergreen.V338.Pagination
import Evergreen.V338.SecretId
import Evergreen.V338.SessionIdHash
import Evergreen.V338.Slack
import Evergreen.V338.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId) (Maybe (Evergreen.V338.Id.Id Evergreen.V338.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V338.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V338.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V338.Discord.Id Evergreen.V338.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId
    , guildId : Evergreen.V338.Discord.Id Evergreen.V338.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V338.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V338.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V338.Discord.Id Evergreen.V338.Discord.UserId
    , channelId : Evergreen.V338.Discord.Id Evergreen.V338.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V338.Id.Id Evergreen.V338.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V338.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V338.Id.Id Evergreen.V338.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V338.Id.Id Evergreen.V338.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V338.Slack.OAuthCode, Evergreen.V338.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V338.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V338.SecretId.SecretId Evergreen.V338.Id.GamePublicId)
