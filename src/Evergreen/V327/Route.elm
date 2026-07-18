module Evergreen.V327.Route exposing (..)

import Evergreen.V327.Discord
import Evergreen.V327.DmChannelId
import Evergreen.V327.Id
import Evergreen.V327.Pagination
import Evergreen.V327.SecretId
import Evergreen.V327.SessionIdHash
import Evergreen.V327.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId) (Maybe (Evergreen.V327.Id.Id Evergreen.V327.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V327.Discord.Id Evergreen.V327.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId
    , guildId : Evergreen.V327.Discord.Id Evergreen.V327.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V327.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V327.Discord.Id Evergreen.V327.Discord.UserId
    , channelId : Evergreen.V327.Discord.Id Evergreen.V327.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V327.Id.Id Evergreen.V327.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V327.Id.Id Evergreen.V327.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V327.Id.Id Evergreen.V327.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V327.Slack.OAuthCode, Evergreen.V327.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V327.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V327.SecretId.SecretId Evergreen.V327.Id.GamePublicId)
