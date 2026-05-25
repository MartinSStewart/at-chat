module Evergreen.V254.Route exposing (..)

import Evergreen.V254.Discord
import Evergreen.V254.DmChannel
import Evergreen.V254.Id
import Evergreen.V254.Pagination
import Evergreen.V254.SecretId
import Evergreen.V254.SessionIdHash
import Evergreen.V254.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId) (Maybe (Evergreen.V254.Id.Id Evergreen.V254.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V254.SecretId.SecretId Evergreen.V254.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V254.Discord.Id Evergreen.V254.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId
    , guildId : Evergreen.V254.Discord.Id Evergreen.V254.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V254.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V254.Discord.Id Evergreen.V254.Discord.UserId
    , channelId : Evergreen.V254.Discord.Id Evergreen.V254.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V254.Id.Id Evergreen.V254.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V254.Id.Id Evergreen.V254.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V254.Id.Id Evergreen.V254.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V254.Slack.OAuthCode, Evergreen.V254.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V254.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V254.SecretId.SecretId Evergreen.V254.Id.GoMatchPublicId)
