module Evergreen.V319.Route exposing (..)

import Evergreen.V319.Discord
import Evergreen.V319.DmChannelId
import Evergreen.V319.Id
import Evergreen.V319.Pagination
import Evergreen.V319.SecretId
import Evergreen.V319.SessionIdHash
import Evergreen.V319.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId) (Maybe (Evergreen.V319.Id.Id Evergreen.V319.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V319.Discord.Id Evergreen.V319.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId
    , guildId : Evergreen.V319.Discord.Id Evergreen.V319.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V319.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V319.Discord.Id Evergreen.V319.Discord.UserId
    , channelId : Evergreen.V319.Discord.Id Evergreen.V319.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V319.Id.Id Evergreen.V319.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V319.Id.Id Evergreen.V319.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V319.Id.Id Evergreen.V319.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V319.Slack.OAuthCode, Evergreen.V319.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V319.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V319.SecretId.SecretId Evergreen.V319.Id.GamePublicId)
