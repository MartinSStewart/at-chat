module Evergreen.V330.Route exposing (..)

import Evergreen.V330.Discord
import Evergreen.V330.DmChannelId
import Evergreen.V330.Id
import Evergreen.V330.Pagination
import Evergreen.V330.SecretId
import Evergreen.V330.SessionIdHash
import Evergreen.V330.Slack
import Evergreen.V330.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId) (Maybe (Evergreen.V330.Id.Id Evergreen.V330.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V330.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V330.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V330.Discord.Id Evergreen.V330.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId
    , guildId : Evergreen.V330.Discord.Id Evergreen.V330.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V330.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V330.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V330.Discord.Id Evergreen.V330.Discord.UserId
    , channelId : Evergreen.V330.Discord.Id Evergreen.V330.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V330.Id.Id Evergreen.V330.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V330.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V330.Id.Id Evergreen.V330.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V330.Id.Id Evergreen.V330.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V330.Slack.OAuthCode, Evergreen.V330.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V330.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V330.SecretId.SecretId Evergreen.V330.Id.GamePublicId)
