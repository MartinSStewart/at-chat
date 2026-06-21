module Evergreen.V293.Route exposing (..)

import Evergreen.V293.Discord
import Evergreen.V293.DmChannel
import Evergreen.V293.Id
import Evergreen.V293.Pagination
import Evergreen.V293.SecretId
import Evergreen.V293.SessionIdHash
import Evergreen.V293.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId) (Maybe (Evergreen.V293.Id.Id Evergreen.V293.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V293.Discord.Id Evergreen.V293.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId
    , guildId : Evergreen.V293.Discord.Id Evergreen.V293.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V293.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V293.Discord.Id Evergreen.V293.Discord.UserId
    , channelId : Evergreen.V293.Discord.Id Evergreen.V293.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V293.Id.Id Evergreen.V293.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V293.Id.Id Evergreen.V293.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V293.Id.Id Evergreen.V293.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V293.Slack.OAuthCode, Evergreen.V293.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V293.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V293.SecretId.SecretId Evergreen.V293.Id.GoMatchPublicId)
