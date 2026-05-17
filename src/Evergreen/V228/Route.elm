module Evergreen.V228.Route exposing (..)

import Evergreen.V228.Discord
import Evergreen.V228.DmChannel
import Evergreen.V228.Id
import Evergreen.V228.Pagination
import Evergreen.V228.SecretId
import Evergreen.V228.SessionIdHash
import Evergreen.V228.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId) (Maybe (Evergreen.V228.Id.Id Evergreen.V228.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V228.SecretId.SecretId Evergreen.V228.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V228.Discord.Id Evergreen.V228.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId
    , guildId : Evergreen.V228.Discord.Id Evergreen.V228.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V228.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V228.Discord.Id Evergreen.V228.Discord.UserId
    , channelId : Evergreen.V228.Discord.Id Evergreen.V228.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V228.Id.Id Evergreen.V228.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V228.Id.Id Evergreen.V228.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V228.Id.Id Evergreen.V228.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V228.Slack.OAuthCode, Evergreen.V228.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V228.Discord.UserAuth)
