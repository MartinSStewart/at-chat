module Evergreen.V308.Route exposing (..)

import Evergreen.V308.Discord
import Evergreen.V308.DmChannelId
import Evergreen.V308.Id
import Evergreen.V308.Pagination
import Evergreen.V308.SecretId
import Evergreen.V308.SessionIdHash
import Evergreen.V308.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId) (Maybe (Evergreen.V308.Id.Id Evergreen.V308.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V308.Discord.Id Evergreen.V308.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId
    , guildId : Evergreen.V308.Discord.Id Evergreen.V308.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V308.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V308.Discord.Id Evergreen.V308.Discord.UserId
    , channelId : Evergreen.V308.Discord.Id Evergreen.V308.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V308.Id.Id Evergreen.V308.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V308.Id.Id Evergreen.V308.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V308.Id.Id Evergreen.V308.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V308.Slack.OAuthCode, Evergreen.V308.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V308.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V308.SecretId.SecretId Evergreen.V308.Id.GamePublicId)
