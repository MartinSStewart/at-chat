module Evergreen.V273.Route exposing (..)

import Evergreen.V273.Discord
import Evergreen.V273.DmChannel
import Evergreen.V273.Id
import Evergreen.V273.Pagination
import Evergreen.V273.SecretId
import Evergreen.V273.SessionIdHash
import Evergreen.V273.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId) (Maybe (Evergreen.V273.Id.Id Evergreen.V273.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V273.Discord.Id Evergreen.V273.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId
    , guildId : Evergreen.V273.Discord.Id Evergreen.V273.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V273.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V273.Discord.Id Evergreen.V273.Discord.UserId
    , channelId : Evergreen.V273.Discord.Id Evergreen.V273.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V273.Id.Id Evergreen.V273.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V273.Id.Id Evergreen.V273.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V273.Id.Id Evergreen.V273.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V273.Slack.OAuthCode, Evergreen.V273.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V273.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V273.SecretId.SecretId Evergreen.V273.Id.GoMatchPublicId)
