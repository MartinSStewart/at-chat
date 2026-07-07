module Evergreen.V305.Route exposing (..)

import Evergreen.V305.Discord
import Evergreen.V305.DmChannelId
import Evergreen.V305.Id
import Evergreen.V305.Pagination
import Evergreen.V305.SecretId
import Evergreen.V305.SessionIdHash
import Evergreen.V305.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId) (Maybe (Evergreen.V305.Id.Id Evergreen.V305.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V305.SecretId.SecretId Evergreen.V305.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V305.Discord.Id Evergreen.V305.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId
    , guildId : Evergreen.V305.Discord.Id Evergreen.V305.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V305.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V305.Discord.Id Evergreen.V305.Discord.UserId
    , channelId : Evergreen.V305.Discord.Id Evergreen.V305.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V305.Id.Id Evergreen.V305.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V305.Id.Id Evergreen.V305.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V305.Id.Id Evergreen.V305.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V305.Slack.OAuthCode, Evergreen.V305.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V305.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V305.SecretId.SecretId Evergreen.V305.Id.GamePublicId)
