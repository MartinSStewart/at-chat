module Evergreen.V242.Route exposing (..)

import Evergreen.V242.Discord
import Evergreen.V242.DmChannel
import Evergreen.V242.Id
import Evergreen.V242.Pagination
import Evergreen.V242.SecretId
import Evergreen.V242.SessionIdHash
import Evergreen.V242.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId) (Maybe (Evergreen.V242.Id.Id Evergreen.V242.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V242.SecretId.SecretId Evergreen.V242.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V242.Discord.Id Evergreen.V242.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId
    , guildId : Evergreen.V242.Discord.Id Evergreen.V242.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V242.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V242.Discord.Id Evergreen.V242.Discord.UserId
    , channelId : Evergreen.V242.Discord.Id Evergreen.V242.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V242.Id.Id Evergreen.V242.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V242.Id.Id Evergreen.V242.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V242.Id.Id Evergreen.V242.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V242.Slack.OAuthCode, Evergreen.V242.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V242.Discord.UserAuth)
