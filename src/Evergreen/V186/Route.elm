module Evergreen.V186.Route exposing (..)

import Evergreen.V186.Discord
import Evergreen.V186.Id
import Evergreen.V186.Pagination
import Evergreen.V186.SecretId
import Evergreen.V186.SessionIdHash
import Evergreen.V186.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId) (Maybe (Evergreen.V186.Id.Id Evergreen.V186.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V186.SecretId.SecretId Evergreen.V186.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId) ThreadRouteWithFriends
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V186.Discord.Id Evergreen.V186.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId
    , guildId : Evergreen.V186.Discord.Id Evergreen.V186.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { otherUserId : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , threadRoute : ThreadRouteWithFriends
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V186.Discord.Id Evergreen.V186.Discord.UserId
    , channelId : Evergreen.V186.Discord.Id Evergreen.V186.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V186.Id.Id Evergreen.V186.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V186.Id.Id Evergreen.V186.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V186.Id.Id Evergreen.V186.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V186.Slack.OAuthCode, Evergreen.V186.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V186.Discord.UserAuth)
