module Evergreen.V304.Route exposing (..)

import Evergreen.V304.Discord
import Evergreen.V304.DmChannelId
import Evergreen.V304.Id
import Evergreen.V304.Pagination
import Evergreen.V304.SecretId
import Evergreen.V304.SessionIdHash
import Evergreen.V304.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId) (Maybe (Evergreen.V304.Id.Id Evergreen.V304.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V304.Discord.Id Evergreen.V304.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId
    , guildId : Evergreen.V304.Discord.Id Evergreen.V304.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V304.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V304.Discord.Id Evergreen.V304.Discord.UserId
    , channelId : Evergreen.V304.Discord.Id Evergreen.V304.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V304.Id.Id Evergreen.V304.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V304.Id.Id Evergreen.V304.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V304.Id.Id Evergreen.V304.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V304.Slack.OAuthCode, Evergreen.V304.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V304.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V304.SecretId.SecretId Evergreen.V304.Id.GamePublicId)
