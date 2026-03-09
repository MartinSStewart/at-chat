module Evergreen.V147.Route exposing (..)

import Evergreen.V147.Discord
import Evergreen.V147.Id
import Evergreen.V147.Pagination
import Evergreen.V147.SecretId
import Evergreen.V147.SessionIdHash
import Evergreen.V147.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId) (Maybe (Evergreen.V147.Id.Id Evergreen.V147.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V147.SecretId.SecretId Evergreen.V147.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V147.Discord.Id Evergreen.V147.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId
    , guildId : Evergreen.V147.Discord.Id Evergreen.V147.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V147.Discord.Id Evergreen.V147.Discord.UserId
    , channelId : Evergreen.V147.Discord.Id Evergreen.V147.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V147.Id.Id Evergreen.V147.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V147.Id.Id Evergreen.V147.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V147.Id.Id Evergreen.V147.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V147.Id.Id Evergreen.V147.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V147.Slack.OAuthCode, Evergreen.V147.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V147.Discord.UserAuth)
