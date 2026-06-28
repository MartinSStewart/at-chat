module Evergreen.V296.Route exposing (..)

import Evergreen.V296.Discord
import Evergreen.V296.DmChannel
import Evergreen.V296.Id
import Evergreen.V296.Pagination
import Evergreen.V296.SecretId
import Evergreen.V296.SessionIdHash
import Evergreen.V296.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId) (Maybe (Evergreen.V296.Id.Id Evergreen.V296.Id.ThreadMessageId)) ShowMembersTab


type ChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Games (Maybe (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId) ThreadRouteWithFriends (Maybe ChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V296.Discord.Id Evergreen.V296.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId
    , guildId : Evergreen.V296.Discord.Id Evergreen.V296.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V296.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe ChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V296.Discord.Id Evergreen.V296.Discord.UserId
    , channelId : Evergreen.V296.Discord.Id Evergreen.V296.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V296.Id.Id Evergreen.V296.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V296.Id.Id Evergreen.V296.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V296.Id.Id Evergreen.V296.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V296.Slack.OAuthCode, Evergreen.V296.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V296.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V296.SecretId.SecretId Evergreen.V296.Id.GamePublicId)
