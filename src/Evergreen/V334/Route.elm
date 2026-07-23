module Evergreen.V334.Route exposing (..)

import Evergreen.V334.Discord
import Evergreen.V334.DmChannelId
import Evergreen.V334.Id
import Evergreen.V334.Pagination
import Evergreen.V334.SecretId
import Evergreen.V334.SessionIdHash
import Evergreen.V334.Slack
import Evergreen.V334.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId) (Maybe (Evergreen.V334.Id.Id Evergreen.V334.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V334.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V334.SecretId.SecretId Evergreen.V334.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V334.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V334.Discord.Id Evergreen.V334.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId
    , guildId : Evergreen.V334.Discord.Id Evergreen.V334.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V334.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V334.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V334.Discord.Id Evergreen.V334.Discord.UserId
    , channelId : Evergreen.V334.Discord.Id Evergreen.V334.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V334.Id.Id Evergreen.V334.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V334.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V334.Id.Id Evergreen.V334.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V334.Id.Id Evergreen.V334.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V334.Slack.OAuthCode, Evergreen.V334.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V334.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V334.SecretId.SecretId Evergreen.V334.Id.GamePublicId)
