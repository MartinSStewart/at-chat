module Evergreen.V298.Route exposing (..)

import Evergreen.V298.Discord
import Evergreen.V298.DmChannel
import Evergreen.V298.Id
import Evergreen.V298.Pagination
import Evergreen.V298.SecretId
import Evergreen.V298.SessionIdHash
import Evergreen.V298.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId) (Maybe (Evergreen.V298.Id.Id Evergreen.V298.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Games (Maybe (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V298.Discord.Id Evergreen.V298.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId
    , guildId : Evergreen.V298.Discord.Id Evergreen.V298.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V298.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V298.Discord.Id Evergreen.V298.Discord.UserId
    , channelId : Evergreen.V298.Discord.Id Evergreen.V298.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V298.Id.Id Evergreen.V298.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe ChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V298.Id.Id Evergreen.V298.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V298.Id.Id Evergreen.V298.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V298.Slack.OAuthCode, Evergreen.V298.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V298.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V298.SecretId.SecretId Evergreen.V298.Id.GamePublicId)
