module Evergreen.V316.Route exposing (..)

import Evergreen.V316.Discord
import Evergreen.V316.DmChannelId
import Evergreen.V316.Id
import Evergreen.V316.Pagination
import Evergreen.V316.SecretId
import Evergreen.V316.SessionIdHash
import Evergreen.V316.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId) (Maybe (Evergreen.V316.Id.Id Evergreen.V316.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V316.Discord.Id Evergreen.V316.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId
    , guildId : Evergreen.V316.Discord.Id Evergreen.V316.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V316.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V316.Discord.Id Evergreen.V316.Discord.UserId
    , channelId : Evergreen.V316.Discord.Id Evergreen.V316.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V316.Id.Id Evergreen.V316.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V316.Id.Id Evergreen.V316.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V316.Id.Id Evergreen.V316.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V316.Slack.OAuthCode, Evergreen.V316.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V316.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V316.SecretId.SecretId Evergreen.V316.Id.GamePublicId)
