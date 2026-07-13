module Evergreen.V318.Route exposing (..)

import Evergreen.V318.Discord
import Evergreen.V318.DmChannelId
import Evergreen.V318.Id
import Evergreen.V318.Pagination
import Evergreen.V318.SecretId
import Evergreen.V318.SessionIdHash
import Evergreen.V318.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId) (Maybe (Evergreen.V318.Id.Id Evergreen.V318.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V318.Discord.Id Evergreen.V318.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId
    , guildId : Evergreen.V318.Discord.Id Evergreen.V318.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V318.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V318.Discord.Id Evergreen.V318.Discord.UserId
    , channelId : Evergreen.V318.Discord.Id Evergreen.V318.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V318.Id.Id Evergreen.V318.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V318.Id.Id Evergreen.V318.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V318.Id.Id Evergreen.V318.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V318.Slack.OAuthCode, Evergreen.V318.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V318.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V318.SecretId.SecretId Evergreen.V318.Id.GamePublicId)
