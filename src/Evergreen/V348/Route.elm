module Evergreen.V348.Route exposing (..)

import Evergreen.V348.Discord
import Evergreen.V348.DmChannelId
import Evergreen.V348.Id
import Evergreen.V348.Pagination
import Evergreen.V348.SecretId
import Evergreen.V348.SessionIdHash
import Evergreen.V348.Slack
import Evergreen.V348.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId) (Maybe (Evergreen.V348.Id.Id Evergreen.V348.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V348.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V348.Discord.Id Evergreen.V348.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V348.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId
    , guildId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V348.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V348.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.UserId
    , channelId : Evergreen.V348.Discord.Id Evergreen.V348.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V348.Id.Id Evergreen.V348.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V348.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V348.Id.Id Evergreen.V348.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V348.Id.Id Evergreen.V348.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V348.Slack.OAuthCode, Evergreen.V348.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V348.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V348.SecretId.SecretId Evergreen.V348.Id.GamePublicId)
