module Evergreen.V238.Route exposing (..)

import Evergreen.V238.Discord
import Evergreen.V238.DmChannel
import Evergreen.V238.Id
import Evergreen.V238.Pagination
import Evergreen.V238.SecretId
import Evergreen.V238.SessionIdHash
import Evergreen.V238.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId) (Maybe (Evergreen.V238.Id.Id Evergreen.V238.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V238.SecretId.SecretId Evergreen.V238.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V238.Discord.Id Evergreen.V238.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId
    , guildId : Evergreen.V238.Discord.Id Evergreen.V238.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V238.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V238.Discord.Id Evergreen.V238.Discord.UserId
    , channelId : Evergreen.V238.Discord.Id Evergreen.V238.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V238.Id.Id Evergreen.V238.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V238.Id.Id Evergreen.V238.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V238.Id.Id Evergreen.V238.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V238.Slack.OAuthCode, Evergreen.V238.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V238.Discord.UserAuth)
