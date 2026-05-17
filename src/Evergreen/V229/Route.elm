module Evergreen.V229.Route exposing (..)

import Evergreen.V229.Discord
import Evergreen.V229.DmChannel
import Evergreen.V229.Id
import Evergreen.V229.Pagination
import Evergreen.V229.SecretId
import Evergreen.V229.SessionIdHash
import Evergreen.V229.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId) (Maybe (Evergreen.V229.Id.Id Evergreen.V229.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V229.SecretId.SecretId Evergreen.V229.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V229.Discord.Id Evergreen.V229.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId
    , guildId : Evergreen.V229.Discord.Id Evergreen.V229.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V229.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V229.Discord.Id Evergreen.V229.Discord.UserId
    , channelId : Evergreen.V229.Discord.Id Evergreen.V229.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V229.Id.Id Evergreen.V229.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V229.Id.Id Evergreen.V229.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V229.Id.Id Evergreen.V229.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V229.Slack.OAuthCode, Evergreen.V229.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V229.Discord.UserAuth)
