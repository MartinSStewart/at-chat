module Evergreen.V252.Route exposing (..)

import Evergreen.V252.Discord
import Evergreen.V252.DmChannel
import Evergreen.V252.Id
import Evergreen.V252.Pagination
import Evergreen.V252.SecretId
import Evergreen.V252.SessionIdHash
import Evergreen.V252.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId) (Maybe (Evergreen.V252.Id.Id Evergreen.V252.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V252.Discord.Id Evergreen.V252.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId
    , guildId : Evergreen.V252.Discord.Id Evergreen.V252.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V252.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V252.Discord.Id Evergreen.V252.Discord.UserId
    , channelId : Evergreen.V252.Discord.Id Evergreen.V252.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V252.Id.Id Evergreen.V252.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V252.Id.Id Evergreen.V252.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V252.Id.Id Evergreen.V252.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V252.Slack.OAuthCode, Evergreen.V252.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V252.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V252.SecretId.SecretId Evergreen.V252.Id.GoMatchPublicId)
