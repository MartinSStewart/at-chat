module Evergreen.V187.Route exposing (..)

import Evergreen.V187.Discord
import Evergreen.V187.Id
import Evergreen.V187.Pagination
import Evergreen.V187.SecretId
import Evergreen.V187.SessionIdHash
import Evergreen.V187.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId) (Maybe (Evergreen.V187.Id.Id Evergreen.V187.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V187.SecretId.SecretId Evergreen.V187.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V187.Discord.Id Evergreen.V187.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId
    , guildId : Evergreen.V187.Discord.Id Evergreen.V187.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V187.Id.Id Evergreen.V187.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V187.Discord.Id Evergreen.V187.Discord.UserId
    , channelId : Evergreen.V187.Discord.Id Evergreen.V187.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V187.Id.Id Evergreen.V187.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V187.Id.Id Evergreen.V187.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V187.Id.Id Evergreen.V187.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V187.Slack.OAuthCode, Evergreen.V187.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V187.Discord.UserAuth)
