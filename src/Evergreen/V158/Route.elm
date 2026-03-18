module Evergreen.V158.Route exposing (..)

import Evergreen.V158.Discord
import Evergreen.V158.Id
import Evergreen.V158.Pagination
import Evergreen.V158.SecretId
import Evergreen.V158.SessionIdHash
import Evergreen.V158.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId) (Maybe (Evergreen.V158.Id.Id Evergreen.V158.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V158.SecretId.SecretId Evergreen.V158.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V158.Discord.Id Evergreen.V158.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId
    , guildId : Evergreen.V158.Discord.Id Evergreen.V158.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V158.Discord.Id Evergreen.V158.Discord.UserId
    , channelId : Evergreen.V158.Discord.Id Evergreen.V158.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V158.Id.Id Evergreen.V158.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V158.Id.Id Evergreen.V158.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V158.Id.Id Evergreen.V158.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute (Evergreen.V158.Id.Id Evergreen.V158.Id.UserId) ThreadRouteWithFriends
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V158.Slack.OAuthCode, Evergreen.V158.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V158.Discord.UserAuth)
