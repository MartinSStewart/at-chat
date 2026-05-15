module Evergreen.V223.Route exposing (..)

import Evergreen.V223.Discord
import Evergreen.V223.DmChannel
import Evergreen.V223.Id
import Evergreen.V223.Pagination
import Evergreen.V223.SecretId
import Evergreen.V223.SessionIdHash
import Evergreen.V223.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId) (Maybe (Evergreen.V223.Id.Id Evergreen.V223.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V223.SecretId.SecretId Evergreen.V223.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V223.Discord.Id Evergreen.V223.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId
    , guildId : Evergreen.V223.Discord.Id Evergreen.V223.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V223.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V223.Discord.Id Evergreen.V223.Discord.UserId
    , channelId : Evergreen.V223.Discord.Id Evergreen.V223.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V223.Id.Id Evergreen.V223.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V223.Id.Id Evergreen.V223.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V223.Id.Id Evergreen.V223.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V223.Slack.OAuthCode, Evergreen.V223.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V223.Discord.UserAuth)
