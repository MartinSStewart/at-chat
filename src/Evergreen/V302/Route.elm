module Evergreen.V302.Route exposing (..)

import Evergreen.V302.Discord
import Evergreen.V302.DmChannel
import Evergreen.V302.Id
import Evergreen.V302.Pagination
import Evergreen.V302.SecretId
import Evergreen.V302.SessionIdHash
import Evergreen.V302.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Maybe (Evergreen.V302.Id.Id Evergreen.V302.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Games (Maybe (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V302.Discord.Id Evergreen.V302.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId
    , guildId : Evergreen.V302.Discord.Id Evergreen.V302.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V302.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V302.Discord.Id Evergreen.V302.Discord.UserId
    , channelId : Evergreen.V302.Discord.Id Evergreen.V302.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V302.Id.Id Evergreen.V302.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V302.Id.Id Evergreen.V302.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V302.Slack.OAuthCode, Evergreen.V302.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V302.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.GamePublicId)
