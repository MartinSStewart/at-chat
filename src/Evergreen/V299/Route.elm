module Evergreen.V299.Route exposing (..)

import Evergreen.V299.Discord
import Evergreen.V299.DmChannel
import Evergreen.V299.Id
import Evergreen.V299.Pagination
import Evergreen.V299.SecretId
import Evergreen.V299.SessionIdHash
import Evergreen.V299.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId) (Maybe (Evergreen.V299.Id.Id Evergreen.V299.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Games (Maybe (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V299.Discord.Id Evergreen.V299.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId
    , guildId : Evergreen.V299.Discord.Id Evergreen.V299.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V299.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V299.Discord.Id Evergreen.V299.Discord.UserId
    , channelId : Evergreen.V299.Discord.Id Evergreen.V299.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V299.Id.Id Evergreen.V299.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V299.Id.Id Evergreen.V299.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V299.Id.Id Evergreen.V299.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V299.Slack.OAuthCode, Evergreen.V299.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V299.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V299.SecretId.SecretId Evergreen.V299.Id.GamePublicId)
