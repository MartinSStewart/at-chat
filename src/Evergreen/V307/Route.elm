module Evergreen.V307.Route exposing (..)

import Evergreen.V307.Discord
import Evergreen.V307.DmChannelId
import Evergreen.V307.Id
import Evergreen.V307.Pagination
import Evergreen.V307.SecretId
import Evergreen.V307.SessionIdHash
import Evergreen.V307.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId) (Maybe (Evergreen.V307.Id.Id Evergreen.V307.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V307.Discord.Id Evergreen.V307.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId
    , guildId : Evergreen.V307.Discord.Id Evergreen.V307.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V307.DmChannelId.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V307.Discord.Id Evergreen.V307.Discord.UserId
    , channelId : Evergreen.V307.Discord.Id Evergreen.V307.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V307.Id.Id Evergreen.V307.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V307.Id.Id Evergreen.V307.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V307.Id.Id Evergreen.V307.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V307.Slack.OAuthCode, Evergreen.V307.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V307.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V307.SecretId.SecretId Evergreen.V307.Id.GamePublicId)
