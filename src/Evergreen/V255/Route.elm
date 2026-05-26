module Evergreen.V255.Route exposing (..)

import Evergreen.V255.Discord
import Evergreen.V255.DmChannel
import Evergreen.V255.Id
import Evergreen.V255.Pagination
import Evergreen.V255.SecretId
import Evergreen.V255.SessionIdHash
import Evergreen.V255.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId) (Maybe (Evergreen.V255.Id.Id Evergreen.V255.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V255.Discord.Id Evergreen.V255.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId
    , guildId : Evergreen.V255.Discord.Id Evergreen.V255.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V255.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V255.Discord.Id Evergreen.V255.Discord.UserId
    , channelId : Evergreen.V255.Discord.Id Evergreen.V255.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V255.Id.Id Evergreen.V255.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V255.Id.Id Evergreen.V255.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V255.Id.Id Evergreen.V255.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V255.Slack.OAuthCode, Evergreen.V255.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V255.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V255.SecretId.SecretId Evergreen.V255.Id.GoMatchPublicId)
