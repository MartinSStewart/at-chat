module Evergreen.V295.Route exposing (..)

import Evergreen.V295.Discord
import Evergreen.V295.DmChannel
import Evergreen.V295.Id
import Evergreen.V295.Pagination
import Evergreen.V295.SecretId
import Evergreen.V295.SessionIdHash
import Evergreen.V295.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId) (Maybe (Evergreen.V295.Id.Id Evergreen.V295.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Games (Maybe (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V295.Discord.Id Evergreen.V295.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId
    , guildId : Evergreen.V295.Discord.Id Evergreen.V295.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V295.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V295.Discord.Id Evergreen.V295.Discord.UserId
    , channelId : Evergreen.V295.Discord.Id Evergreen.V295.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V295.Id.Id Evergreen.V295.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V295.Id.Id Evergreen.V295.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V295.Id.Id Evergreen.V295.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V295.Slack.OAuthCode, Evergreen.V295.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V295.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V295.SecretId.SecretId Evergreen.V295.Id.GamePublicId)
