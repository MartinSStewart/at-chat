module Evergreen.V352.Route exposing (..)

import Evergreen.V352.Discord
import Evergreen.V352.DmChannelId
import Evergreen.V352.Id
import Evergreen.V352.Pagination
import Evergreen.V352.SecretId
import Evergreen.V352.SessionIdHash
import Evergreen.V352.Slack
import Evergreen.V352.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId) (Maybe (Evergreen.V352.Id.Id Evergreen.V352.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V352.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V352.Discord.Id Evergreen.V352.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V352.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId
    , guildId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V352.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V352.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.UserId
    , channelId : Evergreen.V352.Discord.Id Evergreen.V352.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V352.Id.Id Evergreen.V352.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V352.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V352.Id.Id Evergreen.V352.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V352.Id.Id Evergreen.V352.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V352.Slack.OAuthCode, Evergreen.V352.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V352.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V352.SecretId.SecretId Evergreen.V352.Id.GamePublicId)
