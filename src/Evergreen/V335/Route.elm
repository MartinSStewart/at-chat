module Evergreen.V335.Route exposing (..)

import Evergreen.V335.Discord
import Evergreen.V335.DmChannelId
import Evergreen.V335.Id
import Evergreen.V335.Pagination
import Evergreen.V335.SecretId
import Evergreen.V335.SessionIdHash
import Evergreen.V335.Slack
import Evergreen.V335.UserSession


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId) (Maybe (Evergreen.V335.Id.Id Evergreen.V335.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V335.UserSession.ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId) ThreadRouteWithFriends (Maybe Evergreen.V335.UserSession.ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V335.Discord.Id Evergreen.V335.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId
    , guildId : Evergreen.V335.Discord.Id Evergreen.V335.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V335.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe Evergreen.V335.UserSession.ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V335.Discord.Id Evergreen.V335.Discord.UserId
    , channelId : Evergreen.V335.Discord.Id Evergreen.V335.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V335.Id.Id Evergreen.V335.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe Evergreen.V335.UserSession.ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V335.Id.Id Evergreen.V335.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V335.Id.Id Evergreen.V335.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V335.Slack.OAuthCode, Evergreen.V335.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V335.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V335.SecretId.SecretId Evergreen.V335.Id.GamePublicId)
