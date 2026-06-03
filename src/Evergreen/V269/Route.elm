module Evergreen.V269.Route exposing (..)

import Evergreen.V269.Discord
import Evergreen.V269.DmChannel
import Evergreen.V269.Id
import Evergreen.V269.Pagination
import Evergreen.V269.SecretId
import Evergreen.V269.SessionIdHash
import Evergreen.V269.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId) (Maybe (Evergreen.V269.Id.Id Evergreen.V269.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V269.Discord.Id Evergreen.V269.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId
    , guildId : Evergreen.V269.Discord.Id Evergreen.V269.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V269.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V269.Discord.Id Evergreen.V269.Discord.UserId
    , channelId : Evergreen.V269.Discord.Id Evergreen.V269.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V269.Id.Id Evergreen.V269.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe DmChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V269.Id.Id Evergreen.V269.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V269.Id.Id Evergreen.V269.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V269.Slack.OAuthCode, Evergreen.V269.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V269.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V269.SecretId.SecretId Evergreen.V269.Id.GoMatchPublicId)
