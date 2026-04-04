module Evergreen.V190.Route exposing (..)

import Evergreen.V190.Discord
import Evergreen.V190.Id
import Evergreen.V190.Pagination
import Evergreen.V190.SecretId
import Evergreen.V190.SessionIdHash
import Evergreen.V190.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId) (Maybe (Evergreen.V190.Id.Id Evergreen.V190.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V190.SecretId.SecretId Evergreen.V190.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V190.Discord.Id Evergreen.V190.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId
    , guildId : Evergreen.V190.Discord.Id Evergreen.V190.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V190.Discord.Id Evergreen.V190.Discord.UserId
    , channelId : Evergreen.V190.Discord.Id Evergreen.V190.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V190.Id.Id Evergreen.V190.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V190.Id.Id Evergreen.V190.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V190.Id.Id Evergreen.V190.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V190.Slack.OAuthCode, Evergreen.V190.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V190.Discord.UserAuth)
