module Evergreen.V253.Route exposing (..)

import Evergreen.V253.Discord
import Evergreen.V253.DmChannel
import Evergreen.V253.Id
import Evergreen.V253.Pagination
import Evergreen.V253.SecretId
import Evergreen.V253.SessionIdHash
import Evergreen.V253.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId) (Maybe (Evergreen.V253.Id.Id Evergreen.V253.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V253.Discord.Id Evergreen.V253.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId
    , guildId : Evergreen.V253.Discord.Id Evergreen.V253.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V253.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V253.Discord.Id Evergreen.V253.Discord.UserId
    , channelId : Evergreen.V253.Discord.Id Evergreen.V253.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V253.Id.Id Evergreen.V253.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V253.Id.Id Evergreen.V253.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V253.Id.Id Evergreen.V253.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V253.Slack.OAuthCode, Evergreen.V253.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V253.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V253.SecretId.SecretId Evergreen.V253.Id.GoMatchPublicId)
