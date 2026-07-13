module Evergreen.V317.Route exposing (..)

import Evergreen.V317.Discord
import Evergreen.V317.DmChannelId
import Evergreen.V317.Id
import Evergreen.V317.Pagination
import Evergreen.V317.SecretId
import Evergreen.V317.SessionIdHash
import Evergreen.V317.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId) (Maybe (Evergreen.V317.Id.Id Evergreen.V317.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V317.Discord.Id Evergreen.V317.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId
    , guildId : Evergreen.V317.Discord.Id Evergreen.V317.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V317.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V317.Discord.Id Evergreen.V317.Discord.UserId
    , channelId : Evergreen.V317.Discord.Id Evergreen.V317.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V317.Id.Id Evergreen.V317.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V317.Id.Id Evergreen.V317.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V317.Id.Id Evergreen.V317.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V317.Slack.OAuthCode, Evergreen.V317.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V317.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V317.SecretId.SecretId Evergreen.V317.Id.GamePublicId)
