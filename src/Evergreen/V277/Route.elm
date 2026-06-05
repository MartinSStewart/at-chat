module Evergreen.V277.Route exposing (..)

import Evergreen.V277.Discord
import Evergreen.V277.DmChannel
import Evergreen.V277.Id
import Evergreen.V277.Pagination
import Evergreen.V277.SecretId
import Evergreen.V277.SessionIdHash
import Evergreen.V277.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId) (Maybe (Evergreen.V277.Id.Id Evergreen.V277.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V277.Discord.Id Evergreen.V277.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId
    , guildId : Evergreen.V277.Discord.Id Evergreen.V277.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V277.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V277.Discord.Id Evergreen.V277.Discord.UserId
    , channelId : Evergreen.V277.Discord.Id Evergreen.V277.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V277.Id.Id Evergreen.V277.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V277.Id.Id Evergreen.V277.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V277.Id.Id Evergreen.V277.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V277.Slack.OAuthCode, Evergreen.V277.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V277.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V277.SecretId.SecretId Evergreen.V277.Id.GoMatchPublicId)
