module Evergreen.V236.Route exposing (..)

import Evergreen.V236.Discord
import Evergreen.V236.DmChannel
import Evergreen.V236.Id
import Evergreen.V236.Pagination
import Evergreen.V236.SecretId
import Evergreen.V236.SessionIdHash
import Evergreen.V236.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId) (Maybe (Evergreen.V236.Id.Id Evergreen.V236.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V236.SecretId.SecretId Evergreen.V236.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V236.Discord.Id Evergreen.V236.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId
    , guildId : Evergreen.V236.Discord.Id Evergreen.V236.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V236.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V236.Discord.Id Evergreen.V236.Discord.UserId
    , channelId : Evergreen.V236.Discord.Id Evergreen.V236.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V236.Id.Id Evergreen.V236.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V236.Id.Id Evergreen.V236.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V236.Id.Id Evergreen.V236.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V236.Slack.OAuthCode, Evergreen.V236.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V236.Discord.UserAuth)
