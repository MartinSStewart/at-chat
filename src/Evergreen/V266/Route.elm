module Evergreen.V266.Route exposing (..)

import Evergreen.V266.Discord
import Evergreen.V266.DmChannel
import Evergreen.V266.Id
import Evergreen.V266.Pagination
import Evergreen.V266.SecretId
import Evergreen.V266.SessionIdHash
import Evergreen.V266.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId) (Maybe (Evergreen.V266.Id.Id Evergreen.V266.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V266.Discord.Id Evergreen.V266.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId
    , guildId : Evergreen.V266.Discord.Id Evergreen.V266.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V266.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V266.Discord.Id Evergreen.V266.Discord.UserId
    , channelId : Evergreen.V266.Discord.Id Evergreen.V266.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V266.Id.Id Evergreen.V266.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V266.Id.Id Evergreen.V266.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V266.Id.Id Evergreen.V266.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V266.Slack.OAuthCode, Evergreen.V266.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V266.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V266.SecretId.SecretId Evergreen.V266.Id.GoMatchPublicId)
