module Evergreen.V239.Route exposing (..)

import Evergreen.V239.Discord
import Evergreen.V239.DmChannel
import Evergreen.V239.Id
import Evergreen.V239.Pagination
import Evergreen.V239.SecretId
import Evergreen.V239.SessionIdHash
import Evergreen.V239.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId) (Maybe (Evergreen.V239.Id.Id Evergreen.V239.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V239.SecretId.SecretId Evergreen.V239.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V239.Discord.Id Evergreen.V239.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId
    , guildId : Evergreen.V239.Discord.Id Evergreen.V239.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V239.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V239.Discord.Id Evergreen.V239.Discord.UserId
    , channelId : Evergreen.V239.Discord.Id Evergreen.V239.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V239.Id.Id Evergreen.V239.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe DmChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V239.Id.Id Evergreen.V239.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V239.Id.Id Evergreen.V239.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V239.Slack.OAuthCode, Evergreen.V239.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V239.Discord.UserAuth)
