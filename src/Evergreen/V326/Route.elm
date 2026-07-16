module Evergreen.V326.Route exposing (..)

import Evergreen.V326.Discord
import Evergreen.V326.DmChannelId
import Evergreen.V326.Id
import Evergreen.V326.Pagination
import Evergreen.V326.SecretId
import Evergreen.V326.SessionIdHash
import Evergreen.V326.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId) (Maybe (Evergreen.V326.Id.Id Evergreen.V326.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V326.Discord.Id Evergreen.V326.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId
    , guildId : Evergreen.V326.Discord.Id Evergreen.V326.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V326.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V326.Discord.Id Evergreen.V326.Discord.UserId
    , channelId : Evergreen.V326.Discord.Id Evergreen.V326.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V326.Id.Id Evergreen.V326.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V326.Id.Id Evergreen.V326.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V326.Id.Id Evergreen.V326.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V326.Slack.OAuthCode, Evergreen.V326.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V326.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V326.SecretId.SecretId Evergreen.V326.Id.GamePublicId)
