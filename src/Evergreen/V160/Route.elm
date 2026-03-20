module Evergreen.V160.Route exposing (..)

import Evergreen.V160.Discord
import Evergreen.V160.Id
import Evergreen.V160.Pagination
import Evergreen.V160.SecretId
import Evergreen.V160.SessionIdHash
import Evergreen.V160.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId) (Maybe (Evergreen.V160.Id.Id Evergreen.V160.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V160.SecretId.SecretId Evergreen.V160.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V160.Discord.Id Evergreen.V160.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId
    , guildId : Evergreen.V160.Discord.Id Evergreen.V160.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V160.Discord.Id Evergreen.V160.Discord.UserId
    , channelId : Evergreen.V160.Discord.Id Evergreen.V160.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V160.Id.Id Evergreen.V160.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V160.Id.Id Evergreen.V160.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V160.Id.Id Evergreen.V160.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V160.Slack.OAuthCode, Evergreen.V160.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V160.Discord.UserAuth)
