module Evergreen.V309.Route exposing (..)

import Evergreen.V309.Discord
import Evergreen.V309.DmChannelId
import Evergreen.V309.Id
import Evergreen.V309.Pagination
import Evergreen.V309.SecretId
import Evergreen.V309.SessionIdHash
import Evergreen.V309.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId) (Maybe (Evergreen.V309.Id.Id Evergreen.V309.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V309.Discord.Id Evergreen.V309.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId
    , guildId : Evergreen.V309.Discord.Id Evergreen.V309.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V309.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V309.Discord.Id Evergreen.V309.Discord.UserId
    , channelId : Evergreen.V309.Discord.Id Evergreen.V309.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V309.Id.Id Evergreen.V309.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V309.Id.Id Evergreen.V309.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V309.Id.Id Evergreen.V309.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V309.Slack.OAuthCode, Evergreen.V309.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V309.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V309.SecretId.SecretId Evergreen.V309.Id.GamePublicId)
