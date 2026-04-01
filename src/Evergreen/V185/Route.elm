module Evergreen.V185.Route exposing (..)

import Evergreen.V185.Discord
import Evergreen.V185.Id
import Evergreen.V185.Pagination
import Evergreen.V185.SecretId
import Evergreen.V185.SessionIdHash
import Evergreen.V185.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId) (Maybe (Evergreen.V185.Id.Id Evergreen.V185.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V185.SecretId.SecretId Evergreen.V185.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V185.Discord.Id Evergreen.V185.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId
    , guildId : Evergreen.V185.Discord.Id Evergreen.V185.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V185.Discord.Id Evergreen.V185.Discord.UserId
    , channelId : Evergreen.V185.Discord.Id Evergreen.V185.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V185.Id.Id Evergreen.V185.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V185.Id.Id Evergreen.V185.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V185.Id.Id Evergreen.V185.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V185.Slack.OAuthCode, Evergreen.V185.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V185.Discord.UserAuth)
