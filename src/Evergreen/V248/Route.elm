module Evergreen.V248.Route exposing (..)

import Evergreen.V248.Discord
import Evergreen.V248.DmChannel
import Evergreen.V248.Id
import Evergreen.V248.Pagination
import Evergreen.V248.SecretId
import Evergreen.V248.SessionIdHash
import Evergreen.V248.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId) (Maybe (Evergreen.V248.Id.Id Evergreen.V248.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V248.Discord.Id Evergreen.V248.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId
    , guildId : Evergreen.V248.Discord.Id Evergreen.V248.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V248.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V248.Discord.Id Evergreen.V248.Discord.UserId
    , channelId : Evergreen.V248.Discord.Id Evergreen.V248.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V248.Id.Id Evergreen.V248.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V248.Id.Id Evergreen.V248.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V248.Id.Id Evergreen.V248.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V248.Slack.OAuthCode, Evergreen.V248.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V248.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V248.SecretId.SecretId Evergreen.V248.Id.GoMatchPublicId)
