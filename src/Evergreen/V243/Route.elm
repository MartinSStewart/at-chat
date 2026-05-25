module Evergreen.V243.Route exposing (..)

import Evergreen.V243.Discord
import Evergreen.V243.DmChannel
import Evergreen.V243.Id
import Evergreen.V243.Pagination
import Evergreen.V243.SecretId
import Evergreen.V243.SessionIdHash
import Evergreen.V243.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId) (Maybe (Evergreen.V243.Id.Id Evergreen.V243.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V243.Discord.Id Evergreen.V243.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId
    , guildId : Evergreen.V243.Discord.Id Evergreen.V243.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V243.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V243.Discord.Id Evergreen.V243.Discord.UserId
    , channelId : Evergreen.V243.Discord.Id Evergreen.V243.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V243.Id.Id Evergreen.V243.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V243.Id.Id Evergreen.V243.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V243.Id.Id Evergreen.V243.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V243.Slack.OAuthCode, Evergreen.V243.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V243.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V243.SecretId.SecretId Evergreen.V243.Id.GoMatchPublicId)
