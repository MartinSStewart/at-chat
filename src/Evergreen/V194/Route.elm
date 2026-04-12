module Evergreen.V194.Route exposing (..)

import Evergreen.V194.Discord
import Evergreen.V194.Id
import Evergreen.V194.Pagination
import Evergreen.V194.SecretId
import Evergreen.V194.SessionIdHash
import Evergreen.V194.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId) (Maybe (Evergreen.V194.Id.Id Evergreen.V194.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V194.SecretId.SecretId Evergreen.V194.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V194.Discord.Id Evergreen.V194.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId
    , guildId : Evergreen.V194.Discord.Id Evergreen.V194.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V194.Discord.Id Evergreen.V194.Discord.UserId
    , channelId : Evergreen.V194.Discord.Id Evergreen.V194.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V194.Id.Id Evergreen.V194.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V194.Id.Id Evergreen.V194.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V194.Id.Id Evergreen.V194.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V194.Slack.OAuthCode, Evergreen.V194.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V194.Discord.UserAuth)
