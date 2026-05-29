module Evergreen.V261.Route exposing (..)

import Evergreen.V261.Discord
import Evergreen.V261.DmChannel
import Evergreen.V261.Id
import Evergreen.V261.Pagination
import Evergreen.V261.SecretId
import Evergreen.V261.SessionIdHash
import Evergreen.V261.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId) (Maybe (Evergreen.V261.Id.Id Evergreen.V261.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V261.Discord.Id Evergreen.V261.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId
    , guildId : Evergreen.V261.Discord.Id Evergreen.V261.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V261.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V261.Discord.Id Evergreen.V261.Discord.UserId
    , channelId : Evergreen.V261.Discord.Id Evergreen.V261.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V261.Id.Id Evergreen.V261.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V261.Id.Id Evergreen.V261.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V261.Id.Id Evergreen.V261.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V261.Slack.OAuthCode, Evergreen.V261.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V261.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V261.SecretId.SecretId Evergreen.V261.Id.GoMatchPublicId)
