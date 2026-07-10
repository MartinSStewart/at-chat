module Evergreen.V311.Route exposing (..)

import Evergreen.V311.Discord
import Evergreen.V311.DmChannelId
import Evergreen.V311.Id
import Evergreen.V311.Pagination
import Evergreen.V311.SecretId
import Evergreen.V311.SessionIdHash
import Evergreen.V311.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId) (Maybe (Evergreen.V311.Id.Id Evergreen.V311.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V311.Discord.Id Evergreen.V311.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId
    , guildId : Evergreen.V311.Discord.Id Evergreen.V311.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V311.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V311.Discord.Id Evergreen.V311.Discord.UserId
    , channelId : Evergreen.V311.Discord.Id Evergreen.V311.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V311.Id.Id Evergreen.V311.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V311.Id.Id Evergreen.V311.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V311.Id.Id Evergreen.V311.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V311.Slack.OAuthCode, Evergreen.V311.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V311.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V311.SecretId.SecretId Evergreen.V311.Id.GamePublicId)
