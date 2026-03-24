module Evergreen.V169.Route exposing (..)

import Evergreen.V169.Discord
import Evergreen.V169.Id
import Evergreen.V169.Pagination
import Evergreen.V169.SecretId
import Evergreen.V169.SessionIdHash
import Evergreen.V169.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId) (Maybe (Evergreen.V169.Id.Id Evergreen.V169.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V169.SecretId.SecretId Evergreen.V169.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V169.Discord.Id Evergreen.V169.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId
    , guildId : Evergreen.V169.Discord.Id Evergreen.V169.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V169.Discord.Id Evergreen.V169.Discord.UserId
    , channelId : Evergreen.V169.Discord.Id Evergreen.V169.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V169.Id.Id Evergreen.V169.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V169.Id.Id Evergreen.V169.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V169.Id.Id Evergreen.V169.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V169.Slack.OAuthCode, Evergreen.V169.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V169.Discord.UserAuth)
