module Evergreen.V218.Route exposing (..)

import Evergreen.V218.Discord
import Evergreen.V218.DmChannel
import Evergreen.V218.Id
import Evergreen.V218.Pagination
import Evergreen.V218.SecretId
import Evergreen.V218.SessionIdHash
import Evergreen.V218.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId) (Maybe (Evergreen.V218.Id.Id Evergreen.V218.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V218.SecretId.SecretId Evergreen.V218.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V218.Discord.Id Evergreen.V218.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId
    , guildId : Evergreen.V218.Discord.Id Evergreen.V218.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V218.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V218.Discord.Id Evergreen.V218.Discord.UserId
    , channelId : Evergreen.V218.Discord.Id Evergreen.V218.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V218.Id.Id Evergreen.V218.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V218.Id.Id Evergreen.V218.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V218.Id.Id Evergreen.V218.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V218.Slack.OAuthCode, Evergreen.V218.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V218.Discord.UserAuth)
