module Evergreen.V351.Route exposing (..)

import Evergreen.V351.Discord
import Evergreen.V351.DmChannelId
import Evergreen.V351.Id
import Evergreen.V351.Pagination
import Evergreen.V351.SecretId
import Evergreen.V351.SessionIdHash
import Evergreen.V351.Slack
import Evergreen.V351.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId) (Maybe (Evergreen.V351.Id.Id Evergreen.V351.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V351.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V351.Discord.Id Evergreen.V351.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V351.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId
    , guildId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V351.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V351.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.UserId
    , channelId : Evergreen.V351.Discord.Id Evergreen.V351.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V351.Id.Id Evergreen.V351.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V351.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V351.Id.Id Evergreen.V351.Pagination.ItemId)
        }
    | NewGuildRoute
    | GuildRoute (Evergreen.V351.Id.Id Evergreen.V351.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V351.Slack.OAuthCode, Evergreen.V351.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V351.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V351.SecretId.SecretId Evergreen.V351.Id.GamePublicId)
