module Evergreen.V297.Route exposing (..)

import Evergreen.V297.Discord
import Evergreen.V297.DmChannel
import Evergreen.V297.Id
import Evergreen.V297.Pagination
import Evergreen.V297.SecretId
import Evergreen.V297.SessionIdHash
import Evergreen.V297.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId) (Maybe (Evergreen.V297.Id.Id Evergreen.V297.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Games (Maybe (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V297.Discord.Id Evergreen.V297.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId
    , guildId : Evergreen.V297.Discord.Id Evergreen.V297.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V297.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V297.Discord.Id Evergreen.V297.Discord.UserId
    , channelId : Evergreen.V297.Discord.Id Evergreen.V297.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V297.Id.Id Evergreen.V297.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V297.Id.Id Evergreen.V297.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V297.Id.Id Evergreen.V297.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V297.Slack.OAuthCode, Evergreen.V297.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V297.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V297.SecretId.SecretId Evergreen.V297.Id.GamePublicId)
