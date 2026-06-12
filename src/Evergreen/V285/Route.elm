module Evergreen.V285.Route exposing (..)

import Evergreen.V285.Discord
import Evergreen.V285.DmChannel
import Evergreen.V285.Id
import Evergreen.V285.Pagination
import Evergreen.V285.SecretId
import Evergreen.V285.SessionIdHash
import Evergreen.V285.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId) (Maybe (Evergreen.V285.Id.Id Evergreen.V285.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V285.Discord.Id Evergreen.V285.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId
    , guildId : Evergreen.V285.Discord.Id Evergreen.V285.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V285.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V285.Discord.Id Evergreen.V285.Discord.UserId
    , channelId : Evergreen.V285.Discord.Id Evergreen.V285.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V285.Id.Id Evergreen.V285.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V285.Id.Id Evergreen.V285.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V285.Id.Id Evergreen.V285.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V285.Slack.OAuthCode, Evergreen.V285.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V285.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V285.SecretId.SecretId Evergreen.V285.Id.GoMatchPublicId)
