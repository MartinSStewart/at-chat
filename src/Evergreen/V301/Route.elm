module Evergreen.V301.Route exposing (..)

import Evergreen.V301.Discord
import Evergreen.V301.DmChannel
import Evergreen.V301.Id
import Evergreen.V301.Pagination
import Evergreen.V301.SecretId
import Evergreen.V301.SessionIdHash
import Evergreen.V301.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Maybe (Evergreen.V301.Id.Id Evergreen.V301.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Games (Maybe (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V301.Discord.Id Evergreen.V301.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId
    , guildId : Evergreen.V301.Discord.Id Evergreen.V301.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V301.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V301.Discord.Id Evergreen.V301.Discord.UserId
    , channelId : Evergreen.V301.Discord.Id Evergreen.V301.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V301.Id.Id Evergreen.V301.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V301.Id.Id Evergreen.V301.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V301.Slack.OAuthCode, Evergreen.V301.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V301.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.GamePublicId)
