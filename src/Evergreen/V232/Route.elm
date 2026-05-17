module Evergreen.V232.Route exposing (..)

import Evergreen.V232.Discord
import Evergreen.V232.DmChannel
import Evergreen.V232.Id
import Evergreen.V232.Pagination
import Evergreen.V232.SecretId
import Evergreen.V232.SessionIdHash
import Evergreen.V232.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId) (Maybe (Evergreen.V232.Id.Id Evergreen.V232.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V232.SecretId.SecretId Evergreen.V232.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V232.Discord.Id Evergreen.V232.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId
    , guildId : Evergreen.V232.Discord.Id Evergreen.V232.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V232.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V232.Discord.Id Evergreen.V232.Discord.UserId
    , channelId : Evergreen.V232.Discord.Id Evergreen.V232.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V232.Id.Id Evergreen.V232.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V232.Id.Id Evergreen.V232.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V232.Id.Id Evergreen.V232.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V232.Slack.OAuthCode, Evergreen.V232.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V232.Discord.UserAuth)
