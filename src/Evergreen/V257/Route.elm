module Evergreen.V257.Route exposing (..)

import Evergreen.V257.Discord
import Evergreen.V257.DmChannel
import Evergreen.V257.Id
import Evergreen.V257.Pagination
import Evergreen.V257.SecretId
import Evergreen.V257.SessionIdHash
import Evergreen.V257.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId) (Maybe (Evergreen.V257.Id.Id Evergreen.V257.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V257.Discord.Id Evergreen.V257.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId
    , guildId : Evergreen.V257.Discord.Id Evergreen.V257.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V257.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V257.Discord.Id Evergreen.V257.Discord.UserId
    , channelId : Evergreen.V257.Discord.Id Evergreen.V257.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V257.Id.Id Evergreen.V257.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V257.Id.Id Evergreen.V257.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V257.Id.Id Evergreen.V257.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V257.Slack.OAuthCode, Evergreen.V257.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V257.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V257.SecretId.SecretId Evergreen.V257.Id.GoMatchPublicId)
