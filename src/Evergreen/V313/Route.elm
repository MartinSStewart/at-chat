module Evergreen.V313.Route exposing (..)

import Evergreen.V313.Discord
import Evergreen.V313.DmChannelId
import Evergreen.V313.Id
import Evergreen.V313.Pagination
import Evergreen.V313.SecretId
import Evergreen.V313.SessionIdHash
import Evergreen.V313.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId) (Maybe (Evergreen.V313.Id.Id Evergreen.V313.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V313.Discord.Id Evergreen.V313.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId
    , guildId : Evergreen.V313.Discord.Id Evergreen.V313.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V313.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V313.Discord.Id Evergreen.V313.Discord.UserId
    , channelId : Evergreen.V313.Discord.Id Evergreen.V313.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V313.Id.Id Evergreen.V313.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V313.Id.Id Evergreen.V313.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V313.Id.Id Evergreen.V313.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V313.Slack.OAuthCode, Evergreen.V313.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V313.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V313.SecretId.SecretId Evergreen.V313.Id.GamePublicId)
