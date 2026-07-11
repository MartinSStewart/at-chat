module Evergreen.V315.Route exposing (..)

import Evergreen.V315.Discord
import Evergreen.V315.DmChannelId
import Evergreen.V315.Id
import Evergreen.V315.Pagination
import Evergreen.V315.SecretId
import Evergreen.V315.SessionIdHash
import Evergreen.V315.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId) (Maybe (Evergreen.V315.Id.Id Evergreen.V315.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V315.Discord.Id Evergreen.V315.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId
    , guildId : Evergreen.V315.Discord.Id Evergreen.V315.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V315.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V315.Discord.Id Evergreen.V315.Discord.UserId
    , channelId : Evergreen.V315.Discord.Id Evergreen.V315.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V315.Id.Id Evergreen.V315.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V315.Id.Id Evergreen.V315.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V315.Id.Id Evergreen.V315.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V315.Slack.OAuthCode, Evergreen.V315.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V315.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V315.SecretId.SecretId Evergreen.V315.Id.GamePublicId)
