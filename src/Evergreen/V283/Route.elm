module Evergreen.V283.Route exposing (..)

import Evergreen.V283.Discord
import Evergreen.V283.DmChannel
import Evergreen.V283.Id
import Evergreen.V283.Pagination
import Evergreen.V283.SecretId
import Evergreen.V283.SessionIdHash
import Evergreen.V283.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId) (Maybe (Evergreen.V283.Id.Id Evergreen.V283.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V283.Discord.Id Evergreen.V283.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId
    , guildId : Evergreen.V283.Discord.Id Evergreen.V283.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V283.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V283.Discord.Id Evergreen.V283.Discord.UserId
    , channelId : Evergreen.V283.Discord.Id Evergreen.V283.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V283.Id.Id Evergreen.V283.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V283.Id.Id Evergreen.V283.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V283.Id.Id Evergreen.V283.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V283.Slack.OAuthCode, Evergreen.V283.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V283.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V283.SecretId.SecretId Evergreen.V283.Id.GoMatchPublicId)
