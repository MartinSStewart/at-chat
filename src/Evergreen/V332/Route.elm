module Evergreen.V332.Route exposing (..)

import Evergreen.V332.Discord
import Evergreen.V332.DmChannelId
import Evergreen.V332.Id
import Evergreen.V332.Pagination
import Evergreen.V332.SecretId
import Evergreen.V332.SessionIdHash
import Evergreen.V332.Slack
import Evergreen.V332.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId) (Maybe (Evergreen.V332.Id.Id Evergreen.V332.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V332.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V332.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V332.Discord.Id Evergreen.V332.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId
    , guildId : Evergreen.V332.Discord.Id Evergreen.V332.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V332.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V332.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V332.Discord.Id Evergreen.V332.Discord.UserId
    , channelId : Evergreen.V332.Discord.Id Evergreen.V332.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V332.Id.Id Evergreen.V332.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V332.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V332.Id.Id Evergreen.V332.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V332.Id.Id Evergreen.V332.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V332.Slack.OAuthCode, Evergreen.V332.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V332.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V332.SecretId.SecretId Evergreen.V332.Id.GamePublicId)
