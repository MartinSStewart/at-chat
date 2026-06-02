module Evergreen.V267.Route exposing (..)

import Evergreen.V267.Discord
import Evergreen.V267.DmChannel
import Evergreen.V267.Id
import Evergreen.V267.Pagination
import Evergreen.V267.SecretId
import Evergreen.V267.SessionIdHash
import Evergreen.V267.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId) (Maybe (Evergreen.V267.Id.Id Evergreen.V267.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V267.Discord.Id Evergreen.V267.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId
    , guildId : Evergreen.V267.Discord.Id Evergreen.V267.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V267.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V267.Discord.Id Evergreen.V267.Discord.UserId
    , channelId : Evergreen.V267.Discord.Id Evergreen.V267.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V267.Id.Id Evergreen.V267.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V267.Id.Id Evergreen.V267.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V267.Id.Id Evergreen.V267.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V267.Slack.OAuthCode, Evergreen.V267.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V267.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V267.SecretId.SecretId Evergreen.V267.Id.GoMatchPublicId)
