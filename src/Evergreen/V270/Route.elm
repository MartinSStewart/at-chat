module Evergreen.V270.Route exposing (..)

import Evergreen.V270.Discord
import Evergreen.V270.DmChannel
import Evergreen.V270.Id
import Evergreen.V270.Pagination
import Evergreen.V270.SecretId
import Evergreen.V270.SessionIdHash
import Evergreen.V270.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId) (Maybe (Evergreen.V270.Id.Id Evergreen.V270.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V270.Discord.Id Evergreen.V270.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId
    , guildId : Evergreen.V270.Discord.Id Evergreen.V270.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V270.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V270.Discord.Id Evergreen.V270.Discord.UserId
    , channelId : Evergreen.V270.Discord.Id Evergreen.V270.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V270.Id.Id Evergreen.V270.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V270.Id.Id Evergreen.V270.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V270.Id.Id Evergreen.V270.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V270.Slack.OAuthCode, Evergreen.V270.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V270.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V270.SecretId.SecretId Evergreen.V270.Id.GoMatchPublicId)
