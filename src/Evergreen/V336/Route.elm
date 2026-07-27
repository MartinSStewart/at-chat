module Evergreen.V336.Route exposing (..)

import Evergreen.V336.Discord
import Evergreen.V336.DmChannelId
import Evergreen.V336.Id
import Evergreen.V336.Pagination
import Evergreen.V336.SecretId
import Evergreen.V336.SessionIdHash
import Evergreen.V336.Slack
import Evergreen.V336.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId) (Maybe (Evergreen.V336.Id.Id Evergreen.V336.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V336.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V336.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId
    , guildId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V336.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V336.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId
    , channelId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V336.Id.Id Evergreen.V336.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V336.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V336.Id.Id Evergreen.V336.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V336.Id.Id Evergreen.V336.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V336.Slack.OAuthCode, Evergreen.V336.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V336.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V336.SecretId.SecretId Evergreen.V336.Id.GamePublicId)
