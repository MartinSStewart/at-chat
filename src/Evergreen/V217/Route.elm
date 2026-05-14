module Evergreen.V217.Route exposing (..)

import Evergreen.V217.Discord
import Evergreen.V217.DmChannel
import Evergreen.V217.Id
import Evergreen.V217.Pagination
import Evergreen.V217.SecretId
import Evergreen.V217.SessionIdHash
import Evergreen.V217.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId) (Maybe (Evergreen.V217.Id.Id Evergreen.V217.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V217.SecretId.SecretId Evergreen.V217.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V217.Discord.Id Evergreen.V217.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId
    , guildId : Evergreen.V217.Discord.Id Evergreen.V217.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V217.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V217.Discord.Id Evergreen.V217.Discord.UserId
    , channelId : Evergreen.V217.Discord.Id Evergreen.V217.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V217.Id.Id Evergreen.V217.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V217.Id.Id Evergreen.V217.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V217.Id.Id Evergreen.V217.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V217.Slack.OAuthCode, Evergreen.V217.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V217.Discord.UserAuth)
