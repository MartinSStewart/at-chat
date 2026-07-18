module Evergreen.V328.Route exposing (..)

import Evergreen.V328.Discord
import Evergreen.V328.DmChannelId
import Evergreen.V328.Id
import Evergreen.V328.Pagination
import Evergreen.V328.SecretId
import Evergreen.V328.SessionIdHash
import Evergreen.V328.Slack
import Evergreen.V328.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId) (Maybe (Evergreen.V328.Id.Id Evergreen.V328.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V328.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V328.SecretId.SecretId Evergreen.V328.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V328.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V328.Discord.Id Evergreen.V328.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId
    , guildId : Evergreen.V328.Discord.Id Evergreen.V328.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V328.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V328.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V328.Discord.Id Evergreen.V328.Discord.UserId
    , channelId : Evergreen.V328.Discord.Id Evergreen.V328.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V328.Id.Id Evergreen.V328.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V328.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V328.Id.Id Evergreen.V328.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V328.Id.Id Evergreen.V328.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V328.Slack.OAuthCode, Evergreen.V328.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V328.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V328.SecretId.SecretId Evergreen.V328.Id.GamePublicId)
