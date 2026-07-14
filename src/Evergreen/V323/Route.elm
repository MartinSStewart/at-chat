module Evergreen.V323.Route exposing (..)

import Evergreen.V323.Discord
import Evergreen.V323.DmChannelId
import Evergreen.V323.Id
import Evergreen.V323.Pagination
import Evergreen.V323.SecretId
import Evergreen.V323.SessionIdHash
import Evergreen.V323.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId) (Maybe (Evergreen.V323.Id.Id Evergreen.V323.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V323.Discord.Id Evergreen.V323.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId
    , guildId : Evergreen.V323.Discord.Id Evergreen.V323.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V323.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V323.Discord.Id Evergreen.V323.Discord.UserId
    , channelId : Evergreen.V323.Discord.Id Evergreen.V323.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V323.Id.Id Evergreen.V323.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V323.Id.Id Evergreen.V323.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V323.Id.Id Evergreen.V323.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V323.Slack.OAuthCode, Evergreen.V323.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V323.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V323.SecretId.SecretId Evergreen.V323.Id.GamePublicId)
