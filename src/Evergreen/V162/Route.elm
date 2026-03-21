module Evergreen.V162.Route exposing (..)

import Evergreen.V162.Discord
import Evergreen.V162.Id
import Evergreen.V162.Pagination
import Evergreen.V162.SecretId
import Evergreen.V162.SessionIdHash
import Evergreen.V162.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId) (Maybe (Evergreen.V162.Id.Id Evergreen.V162.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V162.SecretId.SecretId Evergreen.V162.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V162.Discord.Id Evergreen.V162.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId
    , guildId : Evergreen.V162.Discord.Id Evergreen.V162.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V162.Discord.Id Evergreen.V162.Discord.UserId
    , channelId : Evergreen.V162.Discord.Id Evergreen.V162.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V162.Id.Id Evergreen.V162.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V162.Id.Id Evergreen.V162.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V162.Id.Id Evergreen.V162.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V162.Id.Id Evergreen.V162.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V162.Slack.OAuthCode, Evergreen.V162.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V162.Discord.UserAuth)
