module Evergreen.V275.Route exposing (..)

import Evergreen.V275.Discord
import Evergreen.V275.DmChannel
import Evergreen.V275.Id
import Evergreen.V275.Pagination
import Evergreen.V275.SecretId
import Evergreen.V275.SessionIdHash
import Evergreen.V275.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId) (Maybe (Evergreen.V275.Id.Id Evergreen.V275.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V275.Discord.Id Evergreen.V275.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId
    , guildId : Evergreen.V275.Discord.Id Evergreen.V275.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V275.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V275.Discord.Id Evergreen.V275.Discord.UserId
    , channelId : Evergreen.V275.Discord.Id Evergreen.V275.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V275.Id.Id Evergreen.V275.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V275.Id.Id Evergreen.V275.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V275.Id.Id Evergreen.V275.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V275.Slack.OAuthCode, Evergreen.V275.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V275.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V275.SecretId.SecretId Evergreen.V275.Id.GoMatchPublicId)
