module Evergreen.V312.Route exposing (..)

import Evergreen.V312.Discord
import Evergreen.V312.DmChannelId
import Evergreen.V312.Id
import Evergreen.V312.Pagination
import Evergreen.V312.SecretId
import Evergreen.V312.SessionIdHash
import Evergreen.V312.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId) (Maybe (Evergreen.V312.Id.Id Evergreen.V312.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V312.Discord.Id Evergreen.V312.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId
    , guildId : Evergreen.V312.Discord.Id Evergreen.V312.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V312.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V312.Discord.Id Evergreen.V312.Discord.UserId
    , channelId : Evergreen.V312.Discord.Id Evergreen.V312.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V312.Id.Id Evergreen.V312.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V312.Id.Id Evergreen.V312.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V312.Id.Id Evergreen.V312.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V312.Slack.OAuthCode, Evergreen.V312.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V312.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V312.SecretId.SecretId Evergreen.V312.Id.GamePublicId)
